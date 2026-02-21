import SwiftUI

struct ClientsPaymentsWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var localization: LocalizationManager

    private let overdueCount = 0
    private let unpaidCount = 0
    private let paidCount = 0
    private let totalAmount = "$0"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(overdueLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(totalAmount)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)

            Text(unpaidLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(paidLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var overdueLabel: String {
        String(format: localization.text(.widgetClientsOverdueFormat), overdueCount)
    }

    private var unpaidLabel: String {
        String(format: localization.text(.widgetClientsUnpaidFormat), unpaidCount)
    }

    private var paidLabel: String {
        String(format: localization.text(.widgetClientsPaidFormat), paidCount)
    }
}
