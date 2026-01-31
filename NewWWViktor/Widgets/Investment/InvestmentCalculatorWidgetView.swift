import SwiftUI

struct InvestmentCalculatorWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        let layout = InvestmentCalculatorLayout(sizeOption: widget.sizeOption)
        let result = InvestmentCalculator.compute(target: widget.investmentComputeTarget,
                                                  targetAmount: widget.investmentTargetAmount,
                                                  startCapital: widget.investmentStartCapital,
                                                  annualRate: widget.investmentRate,
                                                  termYears: widget.investmentTermYears,
                                                  contribution: widget.investmentContribution,
                                                  contributionFrequency: widget.investmentContributionFrequency,
                                                  compoundingFrequency: widget.investmentCompoundingFrequency,
                                                  includeTax: widget.investmentIncludeTax,
                                                  taxRate: widget.investmentTaxRate,
                                                  includeInflation: widget.investmentIncludeInflation,
                                                  inflationRate: widget.investmentInflationRate)
        let breakdown = shouldShowBreakdown
            ? InvestmentCalculator.yearlyBreakdown(startCapital: widget.investmentStartCapital,
                                                   annualRate: widget.investmentRate,
                                                   termYears: widget.investmentTermYears,
                                                   contribution: widget.investmentContribution,
                                                   contributionFrequency: widget.investmentContributionFrequency,
                                                   compoundingFrequency: widget.investmentCompoundingFrequency,
                                                   includeTax: widget.investmentIncludeTax,
                                                   taxRate: widget.investmentTaxRate,
                                                   includeInflation: widget.investmentIncludeInflation,
                                                   inflationRate: widget.investmentInflationRate)
            : []

        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            resultHeader(result: result, layout: layout)

            if shouldShowBreakdown, !breakdown.isEmpty {
                breakdownSection(entries: breakdown, layout: layout)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, layout.topPadding)
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

    private var shouldShowBreakdown: Bool {
        guard widget.sizeOption != .medium else { return false }
        return widget.investmentComputeTarget == .income && widget.investmentShowBreakdown
    }

    private func resultHeader(result: InvestmentCalculatorResult, layout: InvestmentCalculatorLayout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text(.widgetInvestmentResultTitle))
                .font(.system(size: layout.resultTitleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(localization.text(widget.investmentComputeTarget.resultTitleKey))
                    .font(.system(size: layout.resultLabelFontSize, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Text(resultValueText(result: result))
                    .font(.system(size: layout.resultValueFontSize, weight: .bold))
                    .foregroundStyle(.primary)
            }

            HStack {
                Text(localization.text(.widgetInvestmentFinalAmountLabel))
                    .font(.system(size: layout.metaFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(moneyFormatter.string(from: NSNumber(value: result.finalAmount)) ?? "—")
                    .font(.system(size: layout.metaFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(localization.text(.widgetInvestmentIncomeLabel))
                    .font(.system(size: layout.metaFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(moneyFormatter.string(from: NSNumber(value: result.income)) ?? "—")
                    .font(.system(size: layout.metaFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, layout.cardPadding)
        .padding(.vertical, layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func breakdownSection(entries: [InvestmentYearBreakdown], layout: InvestmentCalculatorLayout) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: layout.rowSpacing) {
                breakdownHeader(layout: layout)

                ForEach(entries) { entry in
                    breakdownRow(entry: entry, layout: layout)
                }
            }
            .padding(layout.cardPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func breakdownHeader(layout: InvestmentCalculatorLayout) -> some View {
        HStack(spacing: layout.breakdownColumnSpacing) {
            breakdownHeaderCell(localization.text(.widgetInvestmentBreakdownYear),
                                alignment: .leading,
                                width: layout.breakdownYearWidth,
                                layout: layout)
            breakdownHeaderCell(localization.text(.widgetInvestmentBreakdownStart),
                                alignment: .trailing,
                                width: nil,
                                layout: layout)
            breakdownHeaderCell(localization.text(.widgetInvestmentBreakdownIncome),
                                alignment: .trailing,
                                width: nil,
                                layout: layout)
            breakdownHeaderCell(localization.text(.widgetInvestmentBreakdownContributions),
                                alignment: .trailing,
                                width: nil,
                                layout: layout)
            breakdownHeaderCell(localization.text(.widgetInvestmentBreakdownFinal),
                                alignment: .trailing,
                                width: nil,
                                layout: layout)
        }
    }

    private func breakdownHeaderCell(_ text: String,
                                     alignment: Alignment,
                                     width: CGFloat?,
                                     layout: InvestmentCalculatorLayout) -> some View {
        Text(text)
            .font(.system(size: layout.breakdownHeaderFontSize, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: width, alignment: alignment)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
    }

    private func breakdownRow(entry: InvestmentYearBreakdown, layout: InvestmentCalculatorLayout) -> some View {
        HStack(spacing: layout.breakdownColumnSpacing) {
            Text("\(entry.year)")
                .font(.system(size: layout.breakdownRowFontSize, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: layout.breakdownYearWidth, alignment: .leading)

            breakdownValueCell(entry.startAmount, layout: layout)
            breakdownValueCell(entry.interestIncome, layout: layout)
            breakdownValueCell(entry.contributions, layout: layout)
            breakdownValueCell(entry.endAmount, layout: layout)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
    }

    private func breakdownValueCell(_ value: Double, layout: InvestmentCalculatorLayout) -> some View {
        Text(moneyFormatter.string(from: NSNumber(value: value)) ?? "—")
            .font(.system(size: layout.breakdownRowFontSize, weight: .semibold))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func computePicker(layout: InvestmentCalculatorLayout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localization.text(.widgetInvestmentComputeLabel))
                .font(.system(size: layout.sectionTitleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)

            Picker("", selection: binding(for: \.investmentComputeTarget)) {
                ForEach(InvestmentComputeTarget.allCases) { option in
                    Text(localization.text(option.titleKey)).tag(option)
                }
            }
            .pickerStyle(.radioGroup)
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
                manager.update(updated)
            }
        )
    }

    private func resultValueText(result: InvestmentCalculatorResult) -> String {
        guard result.isValid else { return localization.text(.widgetPlaceholderDash) }
        switch widget.investmentComputeTarget {
        case .rate:
            return percentFormatter.string(from: NSNumber(value: result.computedValue)) ?? "—"
        case .timeToGoal:
            return yearsMonthsString(result.computedValue)
        default:
            return moneyFormatter.string(from: NSNumber(value: result.computedValue)) ?? "—"
        }
    }

    private func yearsMonthsString(_ years: Double) -> String {
        let totalMonths = max(0, Int((years * 12).rounded()))
        let wholeYears = totalMonths / 12
        let months = totalMonths % 12
        let yearsUnit = localization.text(.widgetInvestmentYearsUnit)
        let monthsUnit = localization.text(.widgetInvestmentMonthsUnit)
        if months == 0 {
            return "\(wholeYears) \(yearsUnit)"
        }
        return "\(wholeYears) \(yearsUnit) \(months) \(monthsUnit)"
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

struct InvestmentFieldRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
    }
}

private struct InvestmentCalculatorLayout {
    let sectionSpacing: CGFloat
    let rowSpacing: CGFloat
    let listPadding: CGFloat
    let topPadding: CGFloat
    let cardCornerRadius: CGFloat
    let cardPadding: CGFloat
    let resultTitleFontSize: CGFloat
    let resultLabelFontSize: CGFloat
    let resultValueFontSize: CGFloat
    let metaFontSize: CGFloat
    let sectionTitleFontSize: CGFloat
    let breakdownHeaderFontSize: CGFloat
    let breakdownRowFontSize: CGFloat
    let breakdownColumnSpacing: CGFloat
    let breakdownYearWidth: CGFloat

    init(sizeOption: WidgetSizeOption) {
        switch sizeOption {
        case .small:
            sectionSpacing = 8
            rowSpacing = 8
            listPadding = 4
            topPadding = 4
            cardCornerRadius = 14
            cardPadding = 10
            resultTitleFontSize = 10
            resultLabelFontSize = 12
            resultValueFontSize = 14
            metaFontSize = 10
            sectionTitleFontSize = 10
            breakdownHeaderFontSize = 9
            breakdownRowFontSize = 9
            breakdownColumnSpacing = 6
            breakdownYearWidth = 28
        case .medium:
            sectionSpacing = 10
            rowSpacing = 10
            listPadding = 6
            topPadding = 6
            cardCornerRadius = 16
            cardPadding = 12
            resultTitleFontSize = 11
            resultLabelFontSize = 13
            resultValueFontSize = 16
            metaFontSize = 11
            sectionTitleFontSize = 11
            breakdownHeaderFontSize = 10
            breakdownRowFontSize = 10
            breakdownColumnSpacing = 8
            breakdownYearWidth = 30
        case .large, .extraLarge:
            sectionSpacing = 12
            rowSpacing = 12
            listPadding = 8
            topPadding = 8
            cardCornerRadius = 18
            cardPadding = 14
            resultTitleFontSize = 12
            resultLabelFontSize = 14
            resultValueFontSize = 18
            metaFontSize = 12
            sectionTitleFontSize = 12
            breakdownHeaderFontSize = 11
            breakdownRowFontSize = 11
            breakdownColumnSpacing = 10
            breakdownYearWidth = 34
        }
    }
}
