import SwiftUI

struct LinksWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.openURL) private var openURL
    @State private var expandedGroupIDs: Set<UUID> = []

    var body: some View {
        let layout = LinksWidgetLayout(sizeOption: widget.sizeOption)
        VStack(alignment: .leading, spacing: layout.headerSpacing) {
            Text(localization.text(.widgetLinksTitle))
                .font(.system(size: layout.titleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: layout.rowSpacing) {
                    if allLinks.isEmpty {
                        Text(localization.text(.widgetLinksEmpty))
                            .font(.system(size: layout.emptyFontSize, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } else {
                        ForEach(widget.linkGroups) { group in
                            groupSection(group, layout: layout)
                        }
                    }
                }
                .padding(.vertical, layout.listVerticalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, layout.topPadding)
        .onAppear {
            updateExpandedGroups()
        }
        .onChange(of: widget.linkGroups) { _, _ in
            updateExpandedGroups()
        }
    }

    @ViewBuilder
    private func groupSection(_ group: WidgetLinkGroup, layout: LinksWidgetLayout) -> some View {
        let hasHeader = shouldShowGroupHeader(group)
        let isExpanded = expandedGroupIDs.contains(group.id) || !hasHeader

        VStack(alignment: .leading, spacing: layout.groupSpacing) {
            if hasHeader {
                Button {
                    toggleGroup(group.id)
                } label: {
                    HStack(spacing: 8) {
                        Text(groupTitle(for: group))
                            .font(.system(size: layout.groupTitleFontSize, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("\(group.links.count)")
                            .font(.system(size: layout.groupCountFontSize, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: layout.groupChevronSize, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, layout.groupHeaderPadding)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: layout.rowSpacing) {
                    ForEach(group.links) { link in
                        Button {
                            open(link)
                        } label: {
                            HStack {
                                Text(displayTitle(for: link))
                                    .font(.system(size: layout.rowFontSize, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, layout.rowVerticalPadding)
                            .padding(.horizontal, layout.rowHorizontalPadding)
                            .background(
                                RoundedRectangle(cornerRadius: layout.rowCornerRadius, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var allLinks: [WidgetLink] {
        widget.linkGroups.flatMap { $0.links }
    }

    private func shouldShowGroupHeader(_ group: WidgetLinkGroup) -> Bool {
        if widget.linkGroups.count > 1 { return true }
        return !group.title.trimmed.isEmpty
    }

    private func groupTitle(for group: WidgetLinkGroup) -> String {
        let trimmed = group.title.trimmed
        return trimmed.isEmpty ? localization.text(.widgetLinksUngrouped) : trimmed
    }

    private func updateExpandedGroups() {
        let ids = Set(widget.linkGroups.map(\.id))
        expandedGroupIDs = expandedGroupIDs.intersection(ids)
        if expandedGroupIDs.isEmpty {
            expandedGroupIDs = ids
        }
    }

    private func toggleGroup(_ id: UUID) {
        if expandedGroupIDs.contains(id) {
            expandedGroupIDs.remove(id)
        } else {
            expandedGroupIDs.insert(id)
        }
    }

    private func open(_ link: WidgetLink) {
        guard let url = resolvedURL(from: link.url) else { return }
        openURL(url)
    }

    private func displayTitle(for link: WidgetLink) -> String {
        let trimmedTitle = link.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { return trimmedTitle }

        let trimmedURL = link.url.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = resolvedURL(from: trimmedURL) {
            return url.host ?? trimmedURL
        }

        return trimmedURL.isEmpty ? localization.text(.widgetPlaceholderDash) : trimmedURL
    }

    private func resolvedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }
}

private struct LinksWidgetLayout {
    let titleFontSize: CGFloat
    let rowFontSize: CGFloat
    let emptyFontSize: CGFloat
    let rowSpacing: CGFloat
    let rowVerticalPadding: CGFloat
    let rowHorizontalPadding: CGFloat
    let rowCornerRadius: CGFloat
    let groupTitleFontSize: CGFloat
    let groupCountFontSize: CGFloat
    let groupChevronSize: CGFloat
    let groupHeaderPadding: CGFloat
    let groupSpacing: CGFloat
    let headerSpacing: CGFloat
    let listVerticalPadding: CGFloat
    let topPadding: CGFloat

    init(sizeOption: WidgetSizeOption) {
        switch sizeOption {
        case .small:
            titleFontSize = 10
            rowFontSize = 12
            emptyFontSize = 11
            rowSpacing = 6
            rowVerticalPadding = 6
            rowHorizontalPadding = 10
            rowCornerRadius = 10
            groupTitleFontSize = 11
            groupCountFontSize = 10
            groupChevronSize = 10
            groupHeaderPadding = 6
            groupSpacing = 4
            headerSpacing = 8
            listVerticalPadding = 2
            topPadding = 4
        case .medium:
            titleFontSize = 11
            rowFontSize = 13
            emptyFontSize = 12
            rowSpacing = 8
            rowVerticalPadding = 7
            rowHorizontalPadding = 12
            rowCornerRadius = 12
            groupTitleFontSize = 12
            groupCountFontSize = 11
            groupChevronSize = 11
            groupHeaderPadding = 8
            groupSpacing = 6
            headerSpacing = 10
            listVerticalPadding = 4
            topPadding = 6
        default:
            titleFontSize = 11
            rowFontSize = 13
            emptyFontSize = 12
            rowSpacing = 8
            rowVerticalPadding = 7
            rowHorizontalPadding = 12
            rowCornerRadius = 12
            groupTitleFontSize = 12
            groupCountFontSize = 11
            groupChevronSize = 11
            groupHeaderPadding = 8
            groupSpacing = 6
            headerSpacing = 10
            listVerticalPadding = 4
            topPadding = 6
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
