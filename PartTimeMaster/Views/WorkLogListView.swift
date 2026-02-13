import SwiftUI
import SwiftData

struct WorkLogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkLog.date, order: .reverse) private var allLogs: [WorkLog]

    @State private var displayedMonth: Date = .now
    @State private var selectedDate: Date?
    @State private var selectedLog: WorkLog?

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    /// 현재 표시 중인 월의 기록
    private var filteredLogs: [WorkLog] {
        allLogs.filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
    }

    /// 근무 기록을 날짜별로 그룹핑 (day component → [WorkLog])
    private var logsByDay: [Int: [WorkLog]] {
        Dictionary(grouping: filteredLogs) { calendar.component(.day, from: $0.date) }
    }

    private var totalDays: Int { filteredLogs.count }
    private var totalHours: Double { filteredLogs.reduce(0) { $0 + $1.workedHours } }
    private var totalPay: Int { filteredLogs.reduce(0) { $0 + $1.dailyPay } }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.year().month().locale(Locale(identifier: "ko_KR")))
    }

    /// 선택한 날짜의 근무 기록
    private var selectedDayLogs: [WorkLog] {
        guard let selected = selectedDate else { return [] }
        return filteredLogs.filter { calendar.isDate($0.date, equalTo: selected, toGranularity: .day) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigator
                summaryBar
                ScrollView {
                    VStack(spacing: 16) {
                        calendarGrid
                        if selectedDate != nil {
                            detailPanel
                        }
                    }
                    .padding(.top, 8)
                }
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

    // MARK: - 캘린더 그리드

    private var calendarGrid: some View {
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        // 일요일=1 기준, 0-indexed offset
        let startWeekday = (calendar.component(.weekday, from: firstOfMonth) - 1)

        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return VStack(spacing: 8) {
            // 요일 헤더
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(index == 0 ? .red : (index == 6 ? .blue : .secondary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)

            // 날짜 셀
            LazyVGrid(columns: columns, spacing: 6) {
                // 빈 셀 (시작 요일 이전)
                ForEach(0..<startWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(height: 52)
                }

                // 날짜 셀
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(from: {
                        var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
                        comps.day = day
                        return comps
                    }())!
                    let hasLog = logsByDay[day] != nil
                    let isSelected = selectedDate.map { calendar.isDate($0, equalTo: date, toGranularity: .day) } ?? false
                    let isToday = calendar.isDateInToday(date)
                    let weekday = (startWeekday + day - 1) % 7 // 0=일, 6=토

                    DayCell(
                        day: day,
                        hasLog: hasLog,
                        isSelected: isSelected,
                        isToday: isToday,
                        weekday: weekday,
                        hoursText: logsByDay[day].map { logs in
                            String(format: "%.1f", logs.reduce(0) { $0 + $1.workedHours })
                        }
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isSelected {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - 상세 패널

    private var detailPanel: some View {
        VStack(spacing: 0) {
            if let selected = selectedDate {
                let dateText = selected.formatted(
                    .dateTime.month().day().weekday(.wide).locale(Locale(identifier: "ko_KR"))
                )

                HStack {
                    Text(dateText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                if selectedDayLogs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("근무 기록 없음")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(selectedDayLogs) { log in
                        DetailCard(log: log, onEdit: {
                            selectedLog = log
                        }, onDelete: {
                            withAnimation {
                                modelContext.delete(log)
                                // 삭제 후 해당 날짜에 더 이상 기록 없으면 선택 해제
                                if selectedDayLogs.count <= 1 {
                                    selectedDate = nil
                                }
                            }
                        })
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            selectedDate = nil
            displayedMonth = newDate
        }
    }
}

// MARK: - 날짜 셀

private struct DayCell: View {
    let day: Int
    let hasLog: Bool
    let isSelected: Bool
    let isToday: Bool
    let weekday: Int // 0=일, 6=토
    let hoursText: String?

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day)")
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(dayColor)

            if hasLog, let hours = hoursText {
                Text("\(hours)h")
                    .font(.system(size: 9))
                    .foregroundStyle(.black)
            } else {
                // 높이 유지를 위한 빈 텍스트
                Text(" ")
                    .font(.system(size: 9))
            }

            // 근무일 dot
            Circle()
                .fill(hasLog ? Color.green : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.15))
            } else if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 1)
            }
        }
    }

    private var dayColor: Color {
        if isSelected { return .accentColor }
        if weekday == 0 { return .red }
        if weekday == 6 { return .blue }
        return .primary
    }
}

// MARK: - 상세 카드

private struct DetailCard: View {
    let log: WorkLog
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    "\(log.startTime.formatted(date: .omitted, time: .shortened)) ~ \(log.endTime.formatted(date: .omitted, time: .shortened))",
                    systemImage: "clock"
                )
                .font(.subheadline)

                Spacer()

                Text(String(format: "%.1f시간", log.workedHours))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack {
                Text(log.dailyPay.currencyText)
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .fontWeight(.medium)

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                }

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                }
            }

            if let memo = log.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .confirmationDialog("근무 기록 삭제", isPresented: $showDeleteConfirm) {
            Button("삭제", role: .destructive) { onDelete() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 근무 기록을 삭제하시겠습니까?")
        }
    }
}

#Preview {
    WorkLogListView()
        .modelContainer(for: WorkLog.self, inMemory: true)
}
