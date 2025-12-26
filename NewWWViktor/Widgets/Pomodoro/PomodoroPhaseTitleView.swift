import SwiftUI

struct PomodoroPhaseTitleView: View {
    let text: String
    let isBreak: Bool
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let fontSize: CGFloat
    let color: Color

    var body: some View {
        if isBreak {
            let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            let first = parts.first.map(String.init) ?? text
            let second = parts.dropFirst().joined(separator: " ")
            VStack(alignment: alignment, spacing: spacing) {
                Text(first)
                if !second.isEmpty {
                    Text(second)
                }
            }
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(color)
            .multilineTextAlignment(alignment == .trailing ? .trailing : .center)
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(color)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .center)
        }
    }
}
