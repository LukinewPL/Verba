import SwiftUI
import SwiftData

// MARK: - View

struct HomeView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @State private var vm = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text(lm.t(vm.greeting))
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                HStack(spacing: 30) {
                    Spacer()
                    statCard(
                        icon: "flame.fill",
                        value: vm.streak,
                        label: lm.t("streak"),
                        iconColor: vm.streak > 0 ? Color.orange : Color.gray
                    )
                    
                    statCard(
                        icon: nil,
                        value: vm.todayWords,
                        label: lm.t("words_today"),
                        valueColor: .glassCyan
                    )
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(lm.t("activity"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        HeatmapView(sessions: vm.sessions)
                            .padding(.vertical, 20)
                            .fixedSize()
                            .glassEffect()
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
        }
        .background(Color.deepNavy.ignoresSafeArea())
        .onAppear {
            vm.setup(repository: repository)
        }
    }
    
    private func statCard(icon: String?, value: Int, label: String, iconColor: Color = .white, valueColor: Color = .white) -> some View {
        VStack(spacing: 8) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(iconColor)
            }
            
            Text("\(value)")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(valueColor)
                .contentTransition(.numericText())
                .animation(.spring, value: value)
            
            Text(label)
                .font(.headline.bold())
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 280, height: 200)
        .glassEffect()
    }
}
