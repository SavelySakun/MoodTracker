import Foundation
import Charts

class StatDaysDataSetManager {

  static let shared = StatDaysDataSetManager()
  var currentlyDrawedStat: [DrawableStat]? = [DrawableStat]()
  var minimumDate = SplitDate(ddMMyyyy: "01.01.2015").endOfDay
  var maximumDate = SplitDate(rawDate: Date()).endOfDay
  var groupingType: GroupingType = .day
  var filterResult: StatFilterResult = .success

  private let statDaysRepository = StatDaysRepository()

  func getBarChartDataSet() -> BarChartDataSet? {
    guard let allStatDays = statDaysRepository.getAll(), !allStatDays.isEmpty else {
      filterResult = .noDataAtAll
      return nil
    }
    let dataEntry = prepateDataEntry(from: allStatDays)
    return BarChartDataSet(entries: dataEntry)
  }

  private func prepateDataEntry(from data: [StatDay]) -> [BarChartDataEntry] {
    let timeRangeFilteredData = filterByTimeRange(data: data)
    let grouped = group(data: timeRangeFilteredData)
    let drawableStats = generateDrawableStat(groupedData: grouped)
    let orderedByDateStats = orderByDate(data: drawableStats)

    currentlyDrawedStat = orderedByDateStats
    var dataEntry = [BarChartDataEntry]()

    for (index, drawableStat) in orderedByDateStats.enumerated() {
      let index = Double(index)
      dataEntry.append(BarChartDataEntry(x: index, y: drawableStat.averageState))
    }

    filterResult = dataEntry.isEmpty ? .noDataInTimeRange : .success
    return dataEntry
  }

  private func orderByDate(data: [DrawableStat]) -> [DrawableStat] {
    let sortedByTimeData = data.sorted {
      let date0 = $0.splitDate
      let date1 = $1.splitDate
      return date0.rawDate.timeIntervalSince1970 < date1.rawDate.timeIntervalSince1970
    }
    return sortedByTimeData
  }

  private func filterByTimeRange(data: [StatDay]) -> [StatDay] {
    let timeRangeFilteredData = data.filter { statDay in
      guard let splitDate = statDay.splitDate else { return false }
      let minimumDateInterval = minimumDate.timeIntervalSince1970
      let maximumDateInterval = maximumDate.timeIntervalSince1970
      let statDayInterval = splitDate.rawDate.timeIntervalSince1970
      return statDayInterval >= minimumDateInterval && statDayInterval <= maximumDateInterval
    }
    return timeRangeFilteredData
  }

  private func group(data: [StatDay]) -> [Date: [StatDay]] {
    switch groupingType {
    case .day:
      return data.groupedBy(dateComponents: [.year, .month, .day])
    case .week:
      return data.groupedBy(dateComponents: [.yearForWeekOfYear, .weekOfMonth, .weekOfYear])
    case .month:
      return data.groupedBy(dateComponents: [.year, .month])
    case .year:
      return data.groupedBy(dateComponents: [.year])
    }
  }

  private func generateDrawableStat(groupedData: [Date: [StatDay]]) -> [DrawableStat] {
    var drawableStats = [DrawableStat]()
    groupedData.forEach { date, statDays in
      drawableStats.append(DrawableStat(statDays, date))
    }
    return drawableStats
  }
}
