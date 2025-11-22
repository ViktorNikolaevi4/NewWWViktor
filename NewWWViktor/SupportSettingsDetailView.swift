import SwiftUI
import AppKit

struct SupportSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    callout
                    supportList
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.text(.categorySupport))
                .font(.title3.weight(.semibold))
            Text(localization.text(.supportSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var callout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localization.text(.supportCalloutTitle))
                .font(.headline.weight(.semibold))
            Text(localization.text(.supportCalloutBody))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var supportList: some View {
        VStack(spacing: 16) {
            supportRow(title: localization.text(.supportRowQuestionTitle),
                       actionTitle: localization.text(.supportRowQuestionAction))
            supportRow(title: localization.text(.supportRowNeedHelpTitle),
                       actionTitle: localization.text(.supportRowNeedHelpAction)) {
                sendEmail(subjectKey: .supportEmailSubject)
            }
            supportRow(title: localization.text(.supportRowTourTitle),
                       actionTitle: localization.text(.supportRowTourAction))
            supportRow(title: localization.text(.supportRowIdeaTitle),
                       actionTitle: localization.text(.supportRowIdeaAction)) {
                sendEmail(subjectKey: .supportIdeaEmailSubject)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
        )
    }

    private func supportRow(title: String, actionTitle: String, action: @escaping () -> Void = {}) -> some View {
        HStack {
            Text(title)
                .font(.body.weight(.semibold))
            Spacer()
            Button(actionTitle) {
                action()
            }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
    }

    private func sendEmail(subjectKey: LocalizationKey) {
        let recipient = "v87v87@icloud.com"
        let subject = localization.text(subjectKey)
        let body = ""

        let allowed = CharacterSet.urlQueryAllowed
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? subject
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? body

        guard let url = URL(string: "mailto:\(recipient)?subject=\(subjectEncoded)&body=\(bodyEncoded)") else { return }
        NSWorkspace.shared.open(url)
    }
}
