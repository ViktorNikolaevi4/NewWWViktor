import SwiftUI

struct BackupsSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    backupSection
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
            Text(localization.text(.categoryBackups))
                .font(.title3.weight(.semibold))
            Text(localization.text(.backupsSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.text(.backupsManualTitle))
                .font(.headline.weight(.semibold))

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text(.backupsCreateTitle))
                        .font(.body.weight(.semibold))
                    Text(localization.text(.backupsCreateDescription))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(localization.text(.backupsSaveNowButton)) {}
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
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
}
