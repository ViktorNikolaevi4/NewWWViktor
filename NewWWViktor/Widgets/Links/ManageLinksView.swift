import SwiftUI

struct ManageLinksView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Binding var links: [WidgetLink]
    @State private var searchText = ""

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
                        if links.isEmpty {
                            Text(localization.text(.widgetLinksManageEmpty))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(links) { link in
                                ManageLinkRow(link: binding(for: link)) {
                                    removeLink(id: link.id)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .onMove(perform: moveLinks)
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
                                        removeLink(id: link.id)
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
    }

    private var header: some View {
        HStack {
            Text(localization.text(.widgetLinksManageTitle))
                .font(.system(size: 16, weight: .semibold))
            Spacer()
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
        guard !trimmed.isEmpty else { return links }
        return links.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
            || $0.url.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func addLink() {
        links.append(WidgetLink())
    }

    private func removeLink(id: UUID) {
        links.removeAll { $0.id == id }
    }

    private func moveLinks(from source: IndexSet, to destination: Int) {
        links.move(fromOffsets: source, toOffset: destination)
    }

    private func binding(for link: WidgetLink) -> Binding<WidgetLink> {
        guard let index = links.firstIndex(where: { $0.id == link.id }) else {
            return .constant(link)
        }
        return $links[index]
    }
}

private struct ManageLinkRow: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var link: WidgetLink
    let onDelete: () -> Void

    var body: some View {
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
