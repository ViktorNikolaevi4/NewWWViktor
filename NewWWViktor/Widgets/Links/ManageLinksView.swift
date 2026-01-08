import SwiftUI

struct ManageLinksView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Binding var linkGroups: [WidgetLinkGroup]
    @State private var searchText = ""
    @State private var pendingDeleteGroup: WidgetLinkGroup?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)

            VStack(spacing: 12) {
                header

                TextField(localization.text(.widgetLinksManageSearch), text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if searchText.trimmed.isEmpty {
                    List {
                        if linkGroups.isEmpty {
                            Text(localization.text(.widgetLinksManageEmpty))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach($linkGroups) { $group in
                                Section {
                                    if group.links.isEmpty {
                                        Text(localization.text(.widgetLinksEmptyGroup))
                                            .foregroundStyle(.secondary)
                                            .listRowBackground(Color.clear)
                                    } else {
                                        ForEach($group.links) { $link in
                                            ManageLinkRow(link: $link) {
                                                removeLink(groupID: group.id, linkID: link.id)
                                            }
                                            .listRowBackground(Color.clear)
                                        }
                                        .onMove { indices, newOffset in
                                            moveLinks(groupID: group.id, from: indices, to: newOffset)
                                        }
                                    }
                                } header: {
                                    ManageGroupHeader(title: $group.title,
                                                      groupID: group.id,
                                                      onAddLink: { addLink(to: group.id) },
                                                      onDeleteGroup: requestDeleteGroup)
                                }
                            }
                            .onMove(perform: moveGroups)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            if filteredLinks.isEmpty {
                                Text(localization.text(.widgetLinksManageEmpty))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 16)
                            } else {
                                ForEach(filteredLinks) { link in
                                    ManageLinkRow(link: binding(for: link)) {
                                        removeLinkByID(link.id)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 360, height: 420)
        .alert(item: $pendingDeleteGroup) { group in
            Alert(title: Text(localization.text(.widgetLinksDeleteGroupTitle)),
                  message: Text("\(groupTitle(for: group))\n\(localization.text(.widgetLinksDeleteGroupMessage))"),
                  primaryButton: .destructive(Text(localization.text(.widgetDelete))) {
                      removeGroup(id: group.id)
                  },
                  secondaryButton: .cancel(Text(localization.text(.widgetEisenhowerCancel))))
        }
    }

    private var header: some View {
        HStack {
            Text(localization.text(.widgetLinksManageTitle))
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button {
                addGroup()
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .help(localization.text(.widgetLinksAddGroup))
            Button {
                addLink()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .help(localization.text(.widgetLinksAddLink))
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var filteredLinks: [WidgetLink] {
        let trimmed = searchText.trimmed
        guard !trimmed.isEmpty else { return allLinks }
        return allLinks.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
            || $0.url.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var allLinks: [WidgetLink] {
        linkGroups.flatMap { $0.links }
    }

    private func groupTitle(for group: WidgetLinkGroup) -> String {
        let trimmed = group.title.trimmed
        return trimmed.isEmpty ? localization.text(.widgetLinksUngrouped) : trimmed
    }

    private func addGroup() {
        linkGroups.append(WidgetLinkGroup())
    }

    private func addLink() {
        if linkGroups.isEmpty {
            linkGroups.append(WidgetLinkGroup())
        }
        linkGroups[0].links.append(WidgetLink())
    }

    private func removeGroup(id: UUID) {
        linkGroups.removeAll { $0.id == id }
    }

    private func requestDeleteGroup(_ groupID: UUID) {
        guard let group = linkGroups.first(where: { $0.id == groupID }) else { return }
        if group.links.isEmpty {
            removeGroup(id: groupID)
        } else {
            pendingDeleteGroup = group
        }
    }

    private func addLink(to groupID: UUID) {
        guard let index = linkGroups.firstIndex(where: { $0.id == groupID }) else { return }
        linkGroups[index].links.append(WidgetLink())
    }

    private func removeLink(groupID: UUID, linkID: UUID) {
        guard let groupIndex = linkGroups.firstIndex(where: { $0.id == groupID }) else { return }
        linkGroups[groupIndex].links.removeAll { $0.id == linkID }
    }

    private func removeLinkByID(_ linkID: UUID) {
        for index in linkGroups.indices {
            if linkGroups[index].links.contains(where: { $0.id == linkID }) {
                linkGroups[index].links.removeAll { $0.id == linkID }
                return
            }
        }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        linkGroups.move(fromOffsets: source, toOffset: destination)
    }

    private func moveLinks(groupID: UUID, from source: IndexSet, to destination: Int) {
        guard let index = linkGroups.firstIndex(where: { $0.id == groupID }) else { return }
        linkGroups[index].links.move(fromOffsets: source, toOffset: destination)
    }

    private func binding(for link: WidgetLink) -> Binding<WidgetLink> {
        for groupIndex in linkGroups.indices {
            if let linkIndex = linkGroups[groupIndex].links.firstIndex(where: { $0.id == link.id }) {
                return $linkGroups[groupIndex].links[linkIndex]
            }
        }
        return .constant(link)
    }
}

private struct ManageGroupHeader: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var title: String
    let groupID: UUID
    let onAddLink: () -> Void
    let onDeleteGroup: (UUID) -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField(localization.text(.widgetLinksGroupPlaceholder), text: $title)
                .textFieldStyle(.roundedBorder)

            Button(action: onAddLink) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .help(localization.text(.widgetLinksAddLink))

            Button {
                onDeleteGroup(groupID)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ManageLinkRow: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var link: WidgetLink
    let onDelete: () -> Void

    var body: some View {
        let urlStatus = validationStatus(for: link.url)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField(localization.text(.widgetLinksTitlePlaceholder), text: $link.title)
                    .textFieldStyle(.roundedBorder)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            TextField(localization.text(.widgetLinksURLPlaceholder), text: $link.url)
                .textFieldStyle(.roundedBorder)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(urlStatus == .invalid ? Color.red.opacity(0.9) : Color.clear, lineWidth: 1)
                )

            if urlStatus == .invalid {
                Text(localization.text(.widgetLinksInvalidURL))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private enum URLValidation {
        case empty
        case valid
        case invalid
    }

    private func validationStatus(for raw: String) -> URLValidation {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.contains(where: \.isWhitespace) { return .invalid }

        if let url = URL(string: trimmed), let host = url.host, isAcceptableHost(host) {
            return .valid
        }
        if let url = URL(string: "https://\(trimmed)"), let host = url.host, isAcceptableHost(host) {
            return .valid
        }
        return .invalid
    }

    private func isAcceptableHost(_ host: String) -> Bool {
        if host == "localhost" { return true }
        if host.contains(".") { return true }
        return isIPv4(host)
    }

    private func isIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part), part.count <= 3 else { return false }
            return (0...255).contains(num)
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
