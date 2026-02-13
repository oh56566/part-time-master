import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkLog.date, order: .reverse) private var allLogs: [WorkLog]
    @State private var showingAddSheet = false

    /// 이번 달 근무 기록
    private var thisMonthLogs: [WorkLog] {
        let calendar = Calendar.current
        let now = Date()
        return allLogs.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    /// 이번 달 총 근무시간
    private var totalHours: Double {
        thisMonthLogs.reduce(0) { $0 + $1.workedHours }
    }

    /// 이번 달 총 근무일수
    private var totalDays: Int {
        thisMonthLogs.count
    }

    /// 이번 달 예상 월급
    private var totalPay: Int {
        thisMonthLogs.reduce(0) { $0 + $1.dailyPay }
    }

    /// 최근 기록 5건
    private var recentLogs: [WorkLog] {
        Array(allLogs.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards
                    recentSection
                }
                .padding()
            }
            .navigationTitle("대시보드")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                WorkLogFormView()
            }
        }
    }

    // MARK: - 요약 카드

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "총 근무일수",
                    value: "\(totalDays)일",
                    icon: "calendar",
                    color: .blue
                )
                SummaryCard(
                    title: "총 근무시간",
                    value: String(format: "%.1f시간", totalHours),
                    icon: "clock",
                    color: .orange
                )
            }
            SummaryCard(
                title: "이번 달 예상 월급",
                value: totalPay.currencyText,
                icon: "wonsign.circle",
                color: .green
            )
        }
    }

    // MARK: - 최근 기록

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 근무 기록")
                .font(.headline)

            if recentLogs.isEmpty {
                ContentUnavailableView(
                    "근무 기록이 없습니다",
                    systemImage: "clock.badge.questionmark",
                    description: Text("+ 버튼을 눌러 첫 근무를 기록해보세요")
                )
                .frame(minHeight: 200)
            } else {
                ForEach(recentLogs) { log in
                    RecentLogRow(log: log)
                }
            }
        }
    }

}

// MARK: - 요약 카드 컴포넌트

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 최근 기록 행

private struct RecentLogRow: View {
    let log: WorkLog

    private var dateText: String {
        log.date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "ko_KR")))
    }

    private var timeText: String {
        let start = log.startTime.formatted(date: .omitted, time: .shortened)
        let end = log.endTime.formatted(date: .omitted, time: .shortened)
        return "\(start) ~ \(end)"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f시간", log.workedHours))
                    .font(.subheadline)
                Text("\(log.dailyPay.formatted())원")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: WorkLog.self, inMemory: true)
}
