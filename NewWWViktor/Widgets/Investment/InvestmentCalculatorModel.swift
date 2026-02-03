import Foundation

enum InvestmentComputeTarget: String, Codable, CaseIterable, Identifiable {
    case income
    case rate
    case startCapital
    case timeToGoal
    case contribution

    var id: String { rawValue }

    var titleKey: LocalizationKey {
        switch self {
        case .income:
            return .widgetInvestmentComputeIncome
        case .rate:
            return .widgetInvestmentComputeRate
        case .startCapital:
            return .widgetInvestmentComputeStartCapital
        case .timeToGoal:
            return .widgetInvestmentComputeTime
        case .contribution:
            return .widgetInvestmentComputeContribution
        }
    }

    var resultTitleKey: LocalizationKey {
        switch self {
        case .income:
            return .widgetInvestmentIncomeLabel
        case .rate:
            return .widgetInvestmentRateLabel
        case .startCapital:
            return .widgetInvestmentStartCapitalLabel
        case .timeToGoal:
            return .widgetInvestmentTimeLabel
        case .contribution:
            return .widgetInvestmentContributionLabel
        }
    }
}

enum InvestmentFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var periodsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .yearly: return 1
        }
    }

    var titleKey: LocalizationKey {
        switch self {
        case .monthly:
            return .widgetInvestmentFrequencyMonthly
        case .quarterly:
            return .widgetInvestmentFrequencyQuarterly
        case .yearly:
            return .widgetInvestmentFrequencyYearly
        }
    }
}

struct InvestmentCalculatorResult {
    let computedValue: Double
    let finalAmount: Double
    let income: Double
    let years: Double
    let isValid: Bool
}

struct InvestmentYearBreakdown: Identifiable {
    let year: Int
    let startAmount: Double
    let interestIncome: Double
    let contributions: Double
    let endAmount: Double

    var id: Int { year }
}

struct InvestmentMonthBreakdown: Identifiable {
    let year: Int
    let month: Int
    let startAmount: Double
    let interestIncome: Double
    let contributions: Double
    let endAmount: Double

    var id: Int { year * 100 + month }
}

struct InvestmentCalculator {
    static func compute(target: InvestmentComputeTarget,
                        targetAmount: Double,
                        startCapital: Double,
                        annualRate: Double,
                        termYears: Double,
                        contribution: Double,
                        contributionFrequency: InvestmentFrequency,
                        compoundingFrequency: InvestmentFrequency,
                        includeTax: Bool,
                        taxRate: Double,
                        includeInflation: Bool,
                        inflationRate: Double) -> InvestmentCalculatorResult {
        let years = max(0, termYears)
        let m = Double(contributionFrequency.periodsPerYear)
        let periods = years * m

        func adjustedFinal(for rate: Double, start: Double, contrib: Double, years: Double) -> Double {
            let nominal = futureValue(annualRate: rate,
                                      years: years,
                                      startCapital: start,
                                      contribution: contrib,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: start,
                                 contribution: contrib,
                                 periods: periods,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: years)
        }

        switch target {
        case .income:
            let final = adjustedFinal(for: annualRate, start: startCapital, contrib: contribution, years: years)
            let income = final - (startCapital + contribution * periods)
            return InvestmentCalculatorResult(computedValue: income,
                                              finalAmount: final,
                                              income: income,
                                              years: years,
                                              isValid: true)
        case .rate:
            let solvedRate = solveRate(goal: targetAmount,
                                       startCapital: startCapital,
                                       termYears: years,
                                       contribution: contribution,
                                       contributionFrequency: contributionFrequency,
                                       compoundingFrequency: compoundingFrequency,
                                       includeTax: includeTax,
                                       taxRate: taxRate,
                                       includeInflation: includeInflation,
                                       inflationRate: inflationRate)
            let final = adjustedFinal(for: solvedRate ?? 0, start: startCapital, contrib: contribution, years: years)
            let income = final - (startCapital + contribution * periods)
            return InvestmentCalculatorResult(computedValue: solvedRate ?? 0,
                                              finalAmount: final,
                                              income: income,
                                              years: years,
                                              isValid: solvedRate != nil)
        case .startCapital:
            let solvedStart = solveStartCapital(goal: targetAmount,
                                                annualRate: annualRate,
                                                termYears: years,
                                                contribution: contribution,
                                                contributionFrequency: contributionFrequency,
                                                compoundingFrequency: compoundingFrequency,
                                                includeTax: includeTax,
                                                taxRate: taxRate,
                                                includeInflation: includeInflation,
                                                inflationRate: inflationRate)
            let final = adjustedFinal(for: annualRate, start: solvedStart ?? 0, contrib: contribution, years: years)
            let income = final - ((solvedStart ?? 0) + contribution * periods)
            return InvestmentCalculatorResult(computedValue: solvedStart ?? 0,
                                              finalAmount: final,
                                              income: income,
                                              years: years,
                                              isValid: solvedStart != nil)
        case .timeToGoal:
            let solvedYears = solveYears(goal: targetAmount,
                                         startCapital: startCapital,
                                         annualRate: annualRate,
                                         contribution: contribution,
                                         contributionFrequency: contributionFrequency,
                                         compoundingFrequency: compoundingFrequency,
                                         includeTax: includeTax,
                                         taxRate: taxRate,
                                         includeInflation: includeInflation,
                                         inflationRate: inflationRate)
            let final = adjustedFinal(for: annualRate, start: startCapital, contrib: contribution, years: solvedYears ?? 0)
            let totalPeriods = (solvedYears ?? 0) * m
            let income = final - (startCapital + contribution * totalPeriods)
            return InvestmentCalculatorResult(computedValue: solvedYears ?? 0,
                                              finalAmount: final,
                                              income: income,
                                              years: solvedYears ?? 0,
                                              isValid: solvedYears != nil)
        case .contribution:
            let solvedContribution = solveContribution(goal: targetAmount,
                                                       startCapital: startCapital,
                                                       annualRate: annualRate,
                                                       termYears: years,
                                                       contributionFrequency: contributionFrequency,
                                                       compoundingFrequency: compoundingFrequency,
                                                       includeTax: includeTax,
                                                       taxRate: taxRate,
                                                       includeInflation: includeInflation,
                                                       inflationRate: inflationRate)
            let final = adjustedFinal(for: annualRate, start: startCapital, contrib: solvedContribution ?? 0, years: years)
            let income = final - (startCapital + (solvedContribution ?? 0) * periods)
            return InvestmentCalculatorResult(computedValue: solvedContribution ?? 0,
                                              finalAmount: final,
                                              income: income,
                                              years: years,
                                              isValid: solvedContribution != nil)
        }
    }

    static func yearlyBreakdown(startCapital: Double,
                                annualRate: Double,
                                termYears: Double,
                                contribution: Double,
                                contributionFrequency: InvestmentFrequency,
                                compoundingFrequency: InvestmentFrequency,
                                includeTax: Bool,
                                taxRate: Double,
                                includeInflation: Bool,
                                inflationRate: Double) -> [InvestmentYearBreakdown] {
        let years = max(0, termYears)
        guard years > 0 else { return [] }

        let totalYears = Int(ceil(years))
        let m = Double(contributionFrequency.periodsPerYear)
        var breakdown: [InvestmentYearBreakdown] = []
        breakdown.reserveCapacity(totalYears)

        func adjustedEndValue(for years: Double) -> Double {
            let nominal = futureValue(annualRate: annualRate,
                                      years: years,
                                      startCapital: startCapital,
                                      contribution: contribution,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: startCapital,
                                 contribution: contribution,
                                 periods: years * m,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: years)
        }

        for yearIndex in 1...totalYears {
            let startYear = min(Double(yearIndex - 1), years)
            let endYear = min(Double(yearIndex), years)
            guard endYear > startYear else { continue }

            let startAmount = adjustedEndValue(for: startYear)
            let endAmount = adjustedEndValue(for: endYear)
            let contributions = contribution * m * (endYear - startYear)
            let interestIncome = endAmount - startAmount - contributions

            breakdown.append(InvestmentYearBreakdown(year: yearIndex,
                                                     startAmount: startAmount,
                                                     interestIncome: interestIncome,
                                                     contributions: contributions,
                                                     endAmount: endAmount))
        }

        return breakdown
    }

    static func monthlyBreakdown(startCapital: Double,
                                 annualRate: Double,
                                 termYears: Double,
                                 contribution: Double,
                                 contributionFrequency: InvestmentFrequency,
                                 compoundingFrequency: InvestmentFrequency,
                                 includeTax: Bool,
                                 taxRate: Double,
                                 includeInflation: Bool,
                                 inflationRate: Double,
                                 yearIndex: Int) -> [InvestmentMonthBreakdown] {
        let years = max(0, termYears)
        let totalMonths = Int(ceil(years * 12))
        guard totalMonths > 0, yearIndex > 0 else { return [] }

        let startMonthIndex = (yearIndex - 1) * 12
        let endMonthIndex = min(yearIndex * 12, totalMonths)
        guard endMonthIndex > startMonthIndex else { return [] }

        let m = Double(contributionFrequency.periodsPerYear)
        var breakdown: [InvestmentMonthBreakdown] = []
        breakdown.reserveCapacity(endMonthIndex - startMonthIndex)

        func adjustedEndValue(for years: Double) -> Double {
            let nominal = futureValue(annualRate: annualRate,
                                      years: years,
                                      startCapital: startCapital,
                                      contribution: contribution,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: startCapital,
                                 contribution: contribution,
                                 periods: years * m,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: years)
        }

        for monthIndex in (startMonthIndex + 1)...endMonthIndex {
            let startYear = Double(monthIndex - 1) / 12.0
            let endYear = Double(monthIndex) / 12.0
            guard endYear > startYear else { continue }

            let startAmount = adjustedEndValue(for: startYear)
            let endAmount = adjustedEndValue(for: endYear)
            let contributions = contribution * m * (endYear - startYear)
            let interestIncome = endAmount - startAmount - contributions
            let monthInYear = monthIndex - startMonthIndex

            breakdown.append(InvestmentMonthBreakdown(year: yearIndex,
                                                      month: monthInYear,
                                                      startAmount: startAmount,
                                                      interestIncome: interestIncome,
                                                      contributions: contributions,
                                                      endAmount: endAmount))
        }

        return breakdown
    }

    private static func futureValue(annualRate: Double,
                                    years: Double,
                                    startCapital: Double,
                                    contribution: Double,
                                    contributionFrequency: InvestmentFrequency,
                                    compoundingFrequency: InvestmentFrequency) -> Double {
        let n = Double(compoundingFrequency.periodsPerYear)
        let m = Double(contributionFrequency.periodsPerYear)
        let periods = years * m
        guard periods > 0 else { return startCapital }

        let r = max(0, annualRate) / 100
        let periodicRate: Double
        if r == 0 {
            periodicRate = 0
        } else {
            periodicRate = pow(1 + r / n, n / m) - 1
        }

        if periodicRate == 0 {
            return startCapital + contribution * periods
        }

        let growth = pow(1 + periodicRate, periods)
        let contributions = contribution * (growth - 1) / periodicRate
        return startCapital * growth + contributions
    }

    private static func adjustedValue(nominal: Double,
                                      startCapital: Double,
                                      contribution: Double,
                                      periods: Double,
                                      includeTax: Bool,
                                      taxRate: Double,
                                      includeInflation: Bool,
                                      inflationRate: Double,
                                      years: Double) -> Double {
        let contributedTotal = startCapital + contribution * periods
        let gain = nominal - contributedTotal
        let taxed: Double
        if includeTax, gain > 0 {
            taxed = nominal - gain * max(0, taxRate) / 100
        } else {
            taxed = nominal
        }

        if includeInflation, years > 0 {
            let inflationFactor = pow(1 + max(0, inflationRate) / 100, years)
            return taxed / inflationFactor
        }
        return taxed
    }

    private static func solveRate(goal: Double,
                                  startCapital: Double,
                                  termYears: Double,
                                  contribution: Double,
                                  contributionFrequency: InvestmentFrequency,
                                  compoundingFrequency: InvestmentFrequency,
                                  includeTax: Bool,
                                  taxRate: Double,
                                  includeInflation: Bool,
                                  inflationRate: Double) -> Double? {
        guard goal > 0 else { return nil }
        let m = Double(contributionFrequency.periodsPerYear)
        let periods = termYears * m
        if periods <= 0 { return nil }

        func final(for rate: Double) -> Double {
            let nominal = futureValue(annualRate: rate,
                                      years: termYears,
                                      startCapital: startCapital,
                                      contribution: contribution,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: startCapital,
                                 contribution: contribution,
                                 periods: periods,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: termYears)
        }

        var low = 0.0
        var high = 20.0
        var highValue = final(for: high)
        while highValue < goal && high < 500 {
            high *= 1.6
            highValue = final(for: high)
        }
        guard highValue >= goal else { return nil }

        for _ in 0..<60 {
            let mid = (low + high) / 2
            let value = final(for: mid)
            if value >= goal {
                high = mid
            } else {
                low = mid
            }
        }
        return high
    }

    private static func solveStartCapital(goal: Double,
                                          annualRate: Double,
                                          termYears: Double,
                                          contribution: Double,
                                          contributionFrequency: InvestmentFrequency,
                                          compoundingFrequency: InvestmentFrequency,
                                          includeTax: Bool,
                                          taxRate: Double,
                                          includeInflation: Bool,
                                          inflationRate: Double) -> Double? {
        guard goal > 0, termYears >= 0 else { return nil }
        let m = Double(contributionFrequency.periodsPerYear)
        let periods = termYears * m
        func final(for start: Double) -> Double {
            let nominal = futureValue(annualRate: annualRate,
                                      years: termYears,
                                      startCapital: start,
                                      contribution: contribution,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: start,
                                 contribution: contribution,
                                 periods: periods,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: termYears)
        }

        var low = 0.0
        var high = max(goal, 1)
        var highValue = final(for: high)
        while highValue < goal && high < goal * 100 {
            high *= 1.6
            highValue = final(for: high)
        }
        guard highValue >= goal else { return nil }

        for _ in 0..<60 {
            let mid = (low + high) / 2
            let value = final(for: mid)
            if value >= goal {
                high = mid
            } else {
                low = mid
            }
        }
        return high
    }

    private static func solveContribution(goal: Double,
                                          startCapital: Double,
                                          annualRate: Double,
                                          termYears: Double,
                                          contributionFrequency: InvestmentFrequency,
                                          compoundingFrequency: InvestmentFrequency,
                                          includeTax: Bool,
                                          taxRate: Double,
                                          includeInflation: Bool,
                                          inflationRate: Double) -> Double? {
        guard goal > 0, termYears > 0 else { return nil }
        let m = Double(contributionFrequency.periodsPerYear)
        let periods = termYears * m
        func final(for contrib: Double) -> Double {
            let nominal = futureValue(annualRate: annualRate,
                                      years: termYears,
                                      startCapital: startCapital,
                                      contribution: contrib,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: startCapital,
                                 contribution: contrib,
                                 periods: periods,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: termYears)
        }

        var low = 0.0
        var high = max(goal / max(periods, 1), 1)
        var highValue = final(for: high)
        while highValue < goal && high < goal * 10 {
            high *= 1.6
            highValue = final(for: high)
        }
        guard highValue >= goal else { return nil }

        for _ in 0..<60 {
            let mid = (low + high) / 2
            let value = final(for: mid)
            if value >= goal {
                high = mid
            } else {
                low = mid
            }
        }
        return high
    }

    private static func solveYears(goal: Double,
                                   startCapital: Double,
                                   annualRate: Double,
                                   contribution: Double,
                                   contributionFrequency: InvestmentFrequency,
                                   compoundingFrequency: InvestmentFrequency,
                                   includeTax: Bool,
                                   taxRate: Double,
                                   includeInflation: Bool,
                                   inflationRate: Double) -> Double? {
        guard goal > 0 else { return nil }
        func final(for years: Double) -> Double {
            let m = Double(contributionFrequency.periodsPerYear)
            let periods = years * m
            let nominal = futureValue(annualRate: annualRate,
                                      years: years,
                                      startCapital: startCapital,
                                      contribution: contribution,
                                      contributionFrequency: contributionFrequency,
                                      compoundingFrequency: compoundingFrequency)
            return adjustedValue(nominal: nominal,
                                 startCapital: startCapital,
                                 contribution: contribution,
                                 periods: periods,
                                 includeTax: includeTax,
                                 taxRate: taxRate,
                                 includeInflation: includeInflation,
                                 inflationRate: inflationRate,
                                 years: years)
        }

        var low = 0.0
        var high = 50.0
        var highValue = final(for: high)
        while highValue < goal && high < 200 {
            high *= 1.5
            highValue = final(for: high)
        }
        guard highValue >= goal else { return nil }

        for _ in 0..<60 {
            let mid = (low + high) / 2
            let value = final(for: mid)
            if value >= goal {
                high = mid
            } else {
                low = mid
            }
        }
        return high
    }
}
