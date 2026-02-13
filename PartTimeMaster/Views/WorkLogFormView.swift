import SwiftUI
import SwiftData

struct WorkLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(StorageKey.defaultWage) private var defaultWage: Int = AppConstants.defaultHourlyWage

    /// nil이면 추가 모드, 값이 있으면 수정 모드
    var existingLog: WorkLog?

    @State private var date: Date = .now
    @State private var startTime: Date = .now
    @State private var endTime: Date = .now
    @State private var breakTime: Double = 0
    @State private var hourlyWage: Int = AppConstants.defaultHourlyWage
    @State private var memo: String = ""
    @FocusState private var isWageFocused: Bool

    private var isEditMode: Bool { existingLog != nil }

    /// 저장 가능 여부
    private var canSave: Bool {
        endTime > startTime && hourlyWage > 0
    }

    /// 실시간 계산: 근무시간
    private var previewHours: Double {
        WorkLog.calculateHours(start: startTime, end: endTime, breakMinutes: breakTime)
    }

    /// 실시간 계산: 일급
    private var previewPay: Int {
        WorkLog.calculatePay(hours: previewHours, wage: hourlyWage)
    }

    var body: some View {
        NavigationStack {
            Form {
                dateSection
                timeSection
                wageSection
                memoSection
                previewSection
            }
            .onTapGesture { isWageFocused = false }
            .navigationTitle(isEditMode ? "근무 수정" : "근무 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { loadExistingData() }
        }
    }

    // MARK: - 날짜

    private var dateSection: some View {
        Section("날짜") {
            DatePicker("근무일", selection: $date, displayedComponents: .date)
        }
    }

    // MARK: - 시간

    private var timeSection: some View {
        Section("근무 시간") {
            DatePicker("출근", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("퇴근", selection: $endTime, displayedComponents: .hourAndMinute)
            Stepper("휴게시간: \(Int(breakTime))분", value: $breakTime, in: 0...480, step: 10)
        }
    }

    // MARK: - 시급

    private var wageSection: some View {
        Section("시급") {
            HStack {
                TextField("시급", value: $hourlyWage, format: .number)
                    .keyboardType(.numberPad)
                    .focused($isWageFocused)
                Text("원")
            }
        }
    }

    // MARK: - 메모

    private var memoSection: some View {
        Section("메모") {
            TextField("메모 (선택)", text: $memo)
        }
    }

    // MARK: - 미리보기

    private var previewSection: some View {
        Section("계산 미리보기") {
            if canSave {
                HStack {
                    Text("근무시간")
                    Spacer()
                    Text(String(format: "%.1f시간", previewHours))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("예상 일급")
                    Spacer()
                    Text("\(previewPay.formatted())원")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            } else {
                Text("퇴근 시간이 출근 시간보다 늦어야 하고, 시급은 0보다 커야 합니다")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - 데이터

    private func loadExistingData() {
        if let log = existingLog {
            date = log.date
            startTime = log.startTime
            endTime = log.endTime
            breakTime = log.breakTime
            hourlyWage = log.hourlyWage
            memo = log.memo ?? ""
        } else {
            hourlyWage = defaultWage
        }
    }

    private func save() {
        if let log = existingLog {
            log.date = date
            log.startTime = startTime
            log.endTime = endTime
            log.breakTime = breakTime
            log.hourlyWage = hourlyWage
            log.memo = memo.isEmpty ? nil : memo
        } else {
            let newLog = WorkLog(
                date: date,
                startTime: startTime,
                endTime: endTime,
                breakTime: breakTime,
                hourlyWage: hourlyWage,
                memo: memo.isEmpty ? nil : memo
            )
            modelContext.insert(newLog)
        }
        dismiss()
    }
}

#Preview {
    WorkLogFormView()
        .modelContainer(for: WorkLog.self, inMemory: true)
}
