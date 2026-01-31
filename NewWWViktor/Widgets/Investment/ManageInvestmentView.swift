import SwiftUI

struct ManageInvestmentView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Binding var widget: WidgetInstance
    let onUpdate: (WidgetInstance) -> Void
    @State private var fieldTexts: [Field: String]
    @FocusState private var focusedField: Field?

    private enum Field {
        case target
        case startCapital
        case termYears
        case rate
        case contribution
        case taxRate
        case inflationRate
    }

    init(isPresented: Binding<Bool>,
         widget: Binding<WidgetInstance>,
         onUpdate: @escaping (WidgetInstance) -> Void) {
        _isPresented = isPresented
        _widget = widget
        self.onUpdate = onUpdate
        _fieldTexts = State(initialValue: [
            .target: Self.formatMoney(widget.wrappedValue.investmentTargetAmount),
            .startCapital: Self.formatMoney(widget.wrappedValue.investmentStartCapital),
            .termYears: Self.formatYears(widget.wrappedValue.investmentTermYears),
            .rate: Self.formatPercent(widget.wrappedValue.investmentRate),
            .contribution: Self.formatMoney(widget.wrappedValue.investmentContribution),
            .taxRate: Self.formatPercent(widget.wrappedValue.investmentTaxRate),
            .inflationRate: Self.formatPercent(widget.wrappedValue.investmentInflationRate)
        ])
    }

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
                            numericRow(field: .target,
                                       title: localization.text(.widgetInvestmentTargetLabel),
                                       value: binding(for: \.investmentTargetAmount),
                                       formatter: moneyFormatter)
                        }

                        if shouldShowStartCapital {
                            numericRow(field: .startCapital,
                                       title: localization.text(.widgetInvestmentStartCapitalLabel),
                                       value: binding(for: \.investmentStartCapital),
                                       formatter: moneyFormatter)
                        }

                        if shouldShowTerm {
                            numericRow(field: .termYears,
                                       title: localization.text(.widgetInvestmentTimeLabel),
                                       value: binding(for: \.investmentTermYears),
                                       formatter: yearsFormatter)
                        }

                        if shouldShowRate {
                            numericRow(field: .rate,
                                       title: localization.text(.widgetInvestmentRateLabel),
                                       value: binding(for: \.investmentRate),
                                       formatter: percentFormatter)
                        }

                        if shouldShowContribution {
                            numericRow(field: .contribution,
                                       title: localization.text(.widgetInvestmentContributionLabel),
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
                            numericRow(field: .taxRate,
                                       title: localization.text(.widgetInvestmentTaxRateLabel),
                                       value: binding(for: \.investmentTaxRate),
                                       formatter: percentFormatter)
                        }

                        toggleRow(title: localization.text(.widgetInvestmentInflationLabel),
                                  isOn: binding(for: \.investmentIncludeInflation))

                        if widget.investmentIncludeInflation {
                            numericRow(field: .inflationRate,
                                       title: localization.text(.widgetInvestmentInflationRateLabel),
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

            Picker("", selection: computeTargetBinding) {
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

    private func numericRow(field: Field,
                            title: String,
                            value: Binding<Double>,
                            formatter: NumberFormatter) -> some View {
        let text = textBinding(for: field)
        return InvestmentFieldRow(title: title) {
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .focused($focusedField, equals: field)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    guard let parsed = parseNumber(trimmed, formatter: formatter) else { return }
                    value.wrappedValue = parsed
                }
                .onChange(of: value.wrappedValue) { _, newValue in
                    guard focusedField != field else { return }
                    fieldTexts[field] = ManageInvestmentView.formatNumber(newValue, formatter: formatter)
                }
                .onChange(of: focusedField) { _, newValue in
                    if newValue != field {
                        fieldTexts[field] = ManageInvestmentView.formatNumber(value.wrappedValue, formatter: formatter)
                    }
                }
        }
    }

    private func textBinding(for field: Field) -> Binding<String> {
        Binding(
            get: {
                fieldTexts[field] ?? ""
            },
            set: { newValue in
                fieldTexts[field] = newValue
            }
        )
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

    private var computeTargetBinding: Binding<InvestmentComputeTarget> {
        Binding(
            get: { widget.investmentComputeTarget },
            set: { newValue in
                updateComputeTarget(to: newValue)
            }
        )
    }

    private func updateComputeTarget(to newValue: InvestmentComputeTarget) {
        var updated = widget
        updated.investmentProfiles[updated.investmentComputeTarget] = updated.currentInvestmentInput()
        updated.investmentComputeTarget = newValue
        if let profile = updated.investmentProfiles[newValue] {
            updated.applyInvestmentInput(profile)
        }
        widget = updated
        onUpdate(updated)
        syncFieldTexts(with: updated)
    }

    private func syncFieldTexts(with widget: WidgetInstance) {
        fieldTexts[.target] = ManageInvestmentView.formatMoney(widget.investmentTargetAmount)
        fieldTexts[.startCapital] = ManageInvestmentView.formatMoney(widget.investmentStartCapital)
        fieldTexts[.termYears] = ManageInvestmentView.formatYears(widget.investmentTermYears)
        fieldTexts[.rate] = ManageInvestmentView.formatPercent(widget.investmentRate)
        fieldTexts[.contribution] = ManageInvestmentView.formatMoney(widget.investmentContribution)
        fieldTexts[.taxRate] = ManageInvestmentView.formatPercent(widget.investmentTaxRate)
        fieldTexts[.inflationRate] = ManageInvestmentView.formatPercent(widget.investmentInflationRate)
    }

    private func binding<T>(for keyPath: WritableKeyPath<WidgetInstance, T>) -> Binding<T> {
        Binding(
            get: { widget[keyPath: keyPath] },
            set: { newValue in
                var updated = widget
                updated[keyPath: keyPath] = newValue
                updated.investmentProfiles[updated.investmentComputeTarget] = updated.currentInvestmentInput()
                widget = updated
                onUpdate(updated)
            }
        )
    }

    private var moneyFormatter: NumberFormatter {
        Self.makeMoneyFormatter()
    }

    private var percentFormatter: NumberFormatter {
        Self.makePercentFormatter()
    }

    private var yearsFormatter: NumberFormatter {
        Self.makeYearsFormatter()
    }

    private static func makeMoneyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private static func makePercentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private static func makeYearsFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private static func formatMoney(_ value: Double) -> String {
        formatNumber(value, formatter: makeMoneyFormatter())
    }

    private static func formatPercent(_ value: Double) -> String {
        formatNumber(value, formatter: makePercentFormatter())
    }

    private static func formatYears(_ value: Double) -> String {
        formatNumber(value, formatter: makeYearsFormatter())
    }

    private static func formatNumber(_ value: Double, formatter: NumberFormatter) -> String {
        formatter.string(from: NSNumber(value: value)) ?? ""
    }

    private func parseNumber(_ text: String, formatter: NumberFormatter) -> Double? {
        if let number = formatter.number(from: text) {
            return number.doubleValue
        }
        let decimalSeparator = formatter.decimalSeparator ?? "."
        let normalized = normalizeNumberInput(text, decimalSeparator: decimalSeparator)
        if let number = formatter.number(from: normalized) {
            return number.doubleValue
        }
        if decimalSeparator == "," {
            let swapped = normalized.replacingOccurrences(of: ",", with: ".")
            return formatter.number(from: swapped)?.doubleValue
        }
        let swapped = normalized.replacingOccurrences(of: ".", with: ",")
        return formatter.number(from: swapped)?.doubleValue
    }

    private func normalizeNumberInput(_ text: String, decimalSeparator: String) -> String {
        var result = ""
        var hasSeparator = false
        for scalar in text.unicodeScalars {
            if CharacterSet.decimalDigits.contains(scalar) {
                result.unicodeScalars.append(scalar)
                continue
            }
            if String(scalar) == decimalSeparator, !hasSeparator {
                result.append(decimalSeparator)
                hasSeparator = true
            }
        }
        return result
    }
}
