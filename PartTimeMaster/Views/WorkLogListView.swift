import SwiftUI
import SwiftData

struct WorkLogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkLog.date, order: .reverse) private var allLogs: [WorkLog]

    @State private var displayedMonth: Date = .now
    @State private var selectedLog: WorkLog?

    /// 현재 표시 중인 월의 기록
    private var filteredLogs: [WorkLog] {
        let calendar = Calendar.current
        return allLogs.filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
    }

    private var totalDays: Int { filteredLogs.count }
    private var totalHours: Double { filteredLogs.reduce(0) { $0 + $1.workedHours } }
    private var totalPay: Int { filteredLogs.reduce(0) { $0 + $1.dailyPay } }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.year().month())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigator
                summaryBar
                logList
            }
            .navigationTitle("근무 기록")
            .sheet(item: $selectedLog) { log in
                WorkLogFormView(existingLog: log)
            }
        }
    }

    // MARK: - 월 네비게이터

    private var monthNavigator: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()
            Text(monthTitle)
                .font(.headline)
            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    // MARK: - 요약 바

    private var summaryBar: some View {
        HStack {
            VStack {
                Text("\(totalDays)")
                    .font(.title3).fontWeight(.bold)
                Text("근무일")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                Text(String(format: "%.1f", totalHours))
                    .font(.title3).fontWeight(.bold)
                Text("시간")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                Text(totalPay.currencyText)
                    .font(.title3).fontWeight(.bold)
                Text("급여")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: - 기록 리스트

    private var logList: some View {
        Group {
            if filteredLogs.isEmpty {
                ContentUnavailableView(
                    "기록 없음",
                    systemImage: "tray",
                    description: Text("이 달의 근무 기록이 없습니다")
                )
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        LogRow(log: log)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedLog = log }
                    }
                    .onDelete(perform: deleteLogs)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredLogs[index])
        }
    }

}

// MARK: - 기록 행

private struct LogRow: View {
    let log: WorkLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date.formatted(.dateTime.month(.defaultDigits).day()))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(log.startTime.formatted(date: .omitted, time: .shortened)) ~ \(log.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let memo = log.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f시간", log.workedHours))
                    .font(.subheadline)
                Text("\(log.dailyPay.formatted())원")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkLogListView()
        .modelContainer(for: WorkLog.self, inMemory: true)
}
