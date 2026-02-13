import SwiftUI

struct SettingsView: View {
    @AppStorage(StorageKey.defaultWage) private var defaultWage: Int = AppConstants.defaultHourlyWage
    @AppStorage(StorageKey.payday) private var payday: Int = 25
    @FocusState private var isWageFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 시급") {
                    HStack {
                        TextField("시급", value: $defaultWage, format: .number)
                            .keyboardType(.numberPad)
                            .focused($isWageFocused)
                        Text("원")
                    }
                    Text("새 근무 기록 추가 시 기본값으로 사용됩니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("급여일") {
                    Picker("급여일", selection: $payday) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)일").tag(day)
                        }
                    }
                }

                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onTapGesture { isWageFocused = false }
            .navigationTitle("설정")
        }
    }
}

#Preview {
    SettingsView()
}
