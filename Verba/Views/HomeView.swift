import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @State private var vm = HomeViewModel()
    @State private var animateCircles = false

    var body: some View {
        ZStack {
            homeBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            statCard(icon: "flame.fill", value: vm.streak, label: lm.t("streak"), iconColor: vm.streak > 0 ? .glassMint : .white.opacity(0.4))
                            statCard(icon: "checkmark.circle.fill", value: vm.todayWords, label: lm.t("words_today"), iconColor: .glassTeal)
                        }

                        VStack(spacing: 10) {
                            statCard(icon: "flame.fill", value: vm.streak, label: lm.t("streak"), iconColor: vm.streak > 0 ? .glassMint : .white.opacity(0.4))
                            statCard(icon: "checkmark.circle.fill", value: vm.todayWords, label: lm.t("words_today"), iconColor: .glassTeal)
                        }
                    }

                    activityCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: 1160)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            vm.setup(repository: repository)
            animateCircles = true
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lm.t("welcome_back"))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.62))

                Text(lm.t(vm.greeting))
                    .font(.system(size: 46, weight: .medium, design: .default))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.glassTeal)
                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
            )
        }
        .padding(16)
        .glassPanel(cornerRadius: 22)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(lm.t("activity"), systemImage: "chart.bar.xaxis")
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack {
                Spacer()
                HeatmapView(sessions: vm.sessions)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .glassPanel(cornerRadius: 16, edgeHighlight: Color.white.opacity(0.12))
                Spacer()
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 22)
    }

    private func statCard(icon: String, value: Int, label: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(iconColor)
                        .frame(width: 62, height: 62)
                    .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(iconColor.opacity(0.16))
                            .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(iconColor.opacity(0.42), lineWidth: 1)
                            )
                    )

                Text("\(value)")
                        .font(.system(size: 108, weight: .medium, design: .default).leading(.tight))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: value)
                    .lineLimit(1)
                        .minimumScaleFactor(0.55)

                Spacer(minLength: 0)
            }

            Text(label)
                    .font(.system(size: 56, weight: .semibold, design: .default).leading(.tight))
                    .minimumScaleFactor(0.45)
                .lineLimit(1)
                .foregroundColor(.white.opacity(0.74))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .glassPanel(cornerRadius: 20)
    }

    private var homeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.12, blue: 0.15), Color.glassBack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.glassMint.opacity(0.16))
                .frame(width: 420)
                .offset(x: animateCircles ? 160 : -40, y: animateCircles ? -140 : 100)
                .blur(radius: 80)

            Circle()
                .fill(Color.glassSky.opacity(0.14))
                .frame(width: 360)
                .offset(x: animateCircles ? -180 : 100, y: animateCircles ? 150 : -100)
                .blur(radius: 80)
        }
        .animation(.easeInOut(duration: 18).repeatForever(autoreverses: true), value: animateCircles)
    }
}
