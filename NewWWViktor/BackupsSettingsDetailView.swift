import SwiftUI

struct BackupsSettingsDetailView: View {
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
            Text("Backups")
                .font(.title3.weight(.semibold))
            Text("Keep your miniWW configuration stored safely.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual backup")
                .font(.headline.weight(.semibold))

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create a backup")
                        .font(.body.weight(.semibold))
                    Text("Save the current widgets and their layout.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Save Now") {}
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
