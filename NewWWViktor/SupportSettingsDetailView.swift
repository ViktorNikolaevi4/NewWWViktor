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
            Text("Поддержка")
                .font(.title3.weight(.semibold))
            Text("Если у вас возникли вопросы, предложения или идеи, напишите нам!")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var callout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Нужна помощь?")
                .font(.headline.weight(.semibold))
            Text("Мы всегда готовы помочь с настройкой, импортом виджетов или новыми идеями.")
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
            supportRow(title: "У вас есть вопрос?", actionTitle: "Посетить FAQ")
            supportRow(title: "Вам нужна помощь?", actionTitle: "Связаться с нами")
            supportRow(title: "Посмотреть приветственный экран", actionTitle: "Просмотреть")
            supportRow(title: "Есть идея нового виджета?", actionTitle: "Поделиться")
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
