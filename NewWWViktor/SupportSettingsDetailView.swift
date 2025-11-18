import SwiftUI

struct SupportSettingsDetailView: View {
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
            Text("Support")
                .font(.title3.weight(.semibold))
            Text("Questions, ideas, or feedback? Reach out anytime!")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var callout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Need help?")
                .font(.headline.weight(.semibold))
            Text("We can help with setup, imports, or brainstorming new widgets.")
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
            supportRow(title: "Have a question?", actionTitle: "Visit FAQ")
            supportRow(title: "Need assistance?", actionTitle: "Contact us")
            supportRow(title: "Rewatch the welcome tour", actionTitle: "Open")
            supportRow(title: "Have an idea for a widget?", actionTitle: "Share it")
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

    private func supportRow(title: String, actionTitle: String) -> some View {
        HStack {
            Text(title)
                .font(.body.weight(.semibold))
            Spacer()
            Button(actionTitle) {}
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
    }
}
