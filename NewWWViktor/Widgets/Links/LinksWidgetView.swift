import SwiftUI

struct LinksWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.openURL) private var openURL

    var body: some View {
        let layout = LinksWidgetLayout(sizeOption: widget.sizeOption)
        VStack(alignment: .leading, spacing: layout.headerSpacing) {
            Text(localization.text(.widgetLinksTitle))
                .font(.system(size: layout.titleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: layout.rowSpacing) {
                    if widget.links.isEmpty {
                        Text(localization.text(.widgetLinksEmpty))
                            .font(.system(size: layout.emptyFontSize, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } else {
                        ForEach(widget.links) { link in
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
                .padding(.vertical, layout.listVerticalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, layout.topPadding)
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
            headerSpacing = 10
            listVerticalPadding = 4
            topPadding = 6
        }
    }
}
