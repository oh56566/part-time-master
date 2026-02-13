import Foundation
import SwiftData

/// 근무 기록 모델
@Model
final class WorkLog {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    /// 휴게 시간 (분)
    var breakTime: Double
    /// 기록 당시 적용된 시급
    var hourlyWage: Int
    var memo: String?

    /// 실 근무시간 (시간 단위)
    var workedHours: Double {
        Self.calculateHours(start: startTime, end: endTime, breakMinutes: breakTime)
    }

    /// 일급
    var dailyPay: Int {
        Self.calculatePay(hours: workedHours, wage: hourlyWage)
    }

    /// 근무시간 계산 (저장 전 미리보기용)
    static func calculateHours(start: Date, end: Date, breakMinutes: Double) -> Double {
        let interval = end.timeIntervalSince(start)
        return max(interval / 3600.0 - breakMinutes / 60.0, 0)
    }

    /// 일급 계산 (저장 전 미리보기용)
    static func calculatePay(hours: Double, wage: Int) -> Int {
        Int(hours * Double(wage))
    }

    init(
        date: Date = .now,
        startTime: Date = .now,
        endTime: Date = .now,
        breakTime: Double = 0,
        hourlyWage: Int = AppConstants.defaultHourlyWage,
        memo: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakTime = breakTime
        self.hourlyWage = hourlyWage
        self.memo = memo
    }
}
