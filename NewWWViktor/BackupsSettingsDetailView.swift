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
            Text("Резервные копии")
                .font(.title3.weight(.semibold))
            Text("Храните конфигурации miniWW в безопасном месте.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ручное копирование")
                .font(.headline.weight(.semibold))

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Создать резервную копию")
                        .font(.body.weight(.semibold))
                    Text("Сохраните текущие виджеты и их позицию.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Сохранить сейчас") {}
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
