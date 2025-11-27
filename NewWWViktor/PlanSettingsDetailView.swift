import SwiftUI

struct PlanSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    premiumCard
                    bundleCard
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.text(.categoryPlan))
                .font(.title3.weight(.semibold))
            Text(localization.text(.planSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                appBadge(imageName: "sparkles")

                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.text(.planPremiumTitle))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)

                    Text(localization.text(.planPremiumBody))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(localization.text(.planPremiumTag))
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }

            HStack(spacing: 10) {
                Button(localization.text(.planUpgradeButton)) {
                    // upgrade tap placeholder
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text(.planRestorePrompt))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))

                    Button(localization.text(.planRestoreButton)) {
                        // restore tap placeholder
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.small)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 0.98, green: 0.61, blue: 0.23),
                        Color(red: 0.86, green: 0.32, blue: 0.2)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 14)
    }

    private var bundleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                appBadge(imageName: "sparkles.rectangle.stack.fill")

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text(.planBundleTitle))
                        .font(.headline.weight(.semibold))
                    Text(localization.text(.planBundleBody))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(localization.text(.planBundleButton)) {
                // learn more tap placeholder
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 10)
    }

    private func appBadge(imageName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .frame(width: 60, height: 60)
            Image(systemName: imageName)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}
