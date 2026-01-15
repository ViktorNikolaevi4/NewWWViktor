import SwiftUI

struct ManageInvestmentView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Binding var widget: WidgetInstance
    let onUpdate: (WidgetInstance) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)

            VStack(spacing: 12) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        computePicker

                        if shouldShowGoal {
                            numberRow(title: localization.text(.widgetInvestmentTargetLabel),
                                      value: binding(for: \.investmentTargetAmount),
                                      formatter: moneyFormatter)
                        }

                        if shouldShowStartCapital {
                            numberRow(title: localization.text(.widgetInvestmentStartCapitalLabel),
                                      value: binding(for: \.investmentStartCapital),
                                      formatter: moneyFormatter)
                        }

                        if shouldShowTerm {
                            numberRow(title: localization.text(.widgetInvestmentTimeLabel),
                                      value: binding(for: \.investmentTermYears),
                                      formatter: yearsFormatter)
                        }

                        if shouldShowRate {
                            numberRow(title: localization.text(.widgetInvestmentRateLabel),
                                      value: binding(for: \.investmentRate),
                                      formatter: percentFormatter)
                        }

                        if shouldShowContribution {
                            numberRow(title: localization.text(.widgetInvestmentContributionLabel),
                                      value: binding(for: \.investmentContribution),
                                      formatter: moneyFormatter)

                            pickerRow(title: localization.text(.widgetInvestmentContributionFrequencyLabel),
                                      selection: binding(for: \.investmentContributionFrequency),
                                      options: InvestmentFrequency.allCases) { option in
                                localization.text(option.titleKey)
                            }
                        }

                        pickerRow(title: localization.text(.widgetInvestmentCompoundingFrequencyLabel),
                                  selection: binding(for: \.investmentCompoundingFrequency),
                                  options: InvestmentFrequency.allCases) { option in
                            localization.text(option.titleKey)
                        }

                        toggleRow(title: localization.text(.widgetInvestmentTaxLabel),
                                  isOn: binding(for: \.investmentIncludeTax))

                        if widget.investmentIncludeTax {
                            numberRow(title: localization.text(.widgetInvestmentTaxRateLabel),
                                      value: binding(for: \.investmentTaxRate),
                                      formatter: percentFormatter)
                        }

                        toggleRow(title: localization.text(.widgetInvestmentInflationLabel),
                                  isOn: binding(for: \.investmentIncludeInflation))

                        if widget.investmentIncludeInflation {
                            numberRow(title: localization.text(.widgetInvestmentInflationRateLabel),
                                      value: binding(for: \.investmentInflationRate),
                                      formatter: percentFormatter)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(16)
        }
        .frame(width: 360, height: 520)
    }

    private var header: some View {
        HStack {
            Text(localization.text(.widgetInvestmentManageTitle))
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var computePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text(.widgetInvestmentComputeLabel))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Picker("", selection: binding(for: \.investmentComputeTarget)) {
                ForEach(InvestmentComputeTarget.allCases) { option in
                    Text(localization.text(option.titleKey)).tag(option)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }

    private var shouldShowGoal: Bool {
        switch widget.investmentComputeTarget {
        case .income:
            return false
        case .rate, .startCapital, .timeToGoal, .contribution:
            return true
        }
    }

    private var shouldShowStartCapital: Bool {
        switch widget.investmentComputeTarget {
        case .startCapital:
            return false
        default:
            return true
        }
    }

    private var shouldShowTerm: Bool {
        switch widget.investmentComputeTarget {
        case .timeToGoal:
            return false
        default:
            return true
        }
    }

    private var shouldShowRate: Bool {
        switch widget.investmentComputeTarget {
        case .rate:
            return false
        default:
            return true
        }
    }

    private var shouldShowContribution: Bool {
        switch widget.investmentComputeTarget {
        case .contribution:
            return false
        default:
            return true
        }
    }

    private func numberRow(title: String, value: Binding<Double>, formatter: NumberFormatter) -> some View {
        InvestmentFieldRow(title: title) {
            TextField("", value: value, formatter: formatter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        InvestmentFieldRow(title: title) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
        }
    }

    private func pickerRow<T: Identifiable & Hashable>(title: String,
                                                       selection: Binding<T>,
                                                       options: [T],
                                                       label: @escaping (T) -> String) -> some View {
        InvestmentFieldRow(title: title) {
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func binding<T>(for keyPath: WritableKeyPath<WidgetInstance, T>) -> Binding<T> {
        Binding(
            get: { widget[keyPath: keyPath] },
            set: { newValue in
                var updated = widget
                updated[keyPath: keyPath] = newValue
                widget = updated
                onUpdate(updated)
            }
        )
    }

    private var moneyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private var yearsFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }
}
