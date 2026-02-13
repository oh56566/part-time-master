import Foundation

extension Int {
    /// 통화 형식 문자열 (예: "1,234,000원")
    var currencyText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(number)원"
    }
}
