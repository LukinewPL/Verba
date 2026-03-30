import SwiftUI
import SwiftData
import Combine

struct SpeedRoundView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @Environment(AppCoordinator.self) private var coordinator
    @State private var vm: SpeedRoundViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(set: WordSet) {
        _vm = State(initialValue: SpeedRoundViewModel(set: set))
    }

    var body: some View {
        ZStack {
            speedBackground

            Group {
                if !vm.isStarted {
                    startView
                } else if vm.isFinished {
                    finishedView
                } else {
                    gameView
                }
            }
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .overlay {
            vm.feedbackColor.opacity(0.24)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onReceive(timerPublisher) { _ in
            vm.tick()
        }
        .onAppear {
            coordinator.enterFocusedMode()
            vm.setup(repository: repository)
        }
        .onDisappear {
            coordinator.exitFocusedMode()
            vm.saveSession()
        }
        .navigationTitle(lm.t("speed_round"))
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    private var startView: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.glassCyan.opacity(0.5), Color.blue.opacity(0.18), .clear],
                                center: .center,
                                startRadius: 6,
                                endRadius: 74
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 66, height: 66)
                        .overlay(
                            Circle()
                                .stroke(Color.glassCyan.opacity(0.45), lineWidth: 1.2)
                        )

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.glassCyan)
                }

                VStack(spacing: 8) {
                    Text(lm.t("speed_round"))
                        .font(.system(size: 30, weight: .medium, design: .default))
                        .foregroundColor(.white)
                    Text(vm.set.name)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    pill(icon: "trophy.fill", label: "\(lm.t("record")): \(vm.set.bestScore)")
                    pill(icon: "timer", label: "60s")
                    pill(icon: "text.book.closed.fill", label: "\(vm.set.words.count) \(lm.t("words"))")
                }
                .frame(maxWidth: .infinity)

                Button {
                    vm.startGame()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { isFocused = true }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text(lm.t("start"))
                    }
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.glassCyan.opacity(0.95), Color.blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: Color.glassCyan.opacity(0.22), radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
                .pressAnimation()
            }
            .padding(18)
            .glassPanel(cornerRadius: 20, edgeHighlight: Color.glassCyan.opacity(0.2))
            .frame(maxWidth: 760)

            Spacer(minLength: 0)
        }
    }

    private var finishedView: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Text(lm.t("time_up"))
                    .font(.system(size: 30, weight: .medium, design: .default))
                    .foregroundColor(.white)

                if vm.showRecordBlast {
                    Text("🏆 \(lm.t("new_record"))!")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.orange)
                        .transition(.scale.combined(with: .opacity))
                }

                Text("\(lm.t("score")): \(vm.correctCount)")
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundColor(.glassCyan)

                Button(lm.t("done")) { dismiss() }
                    .buttonStyle(GlassButtonStyle())
            }
            .padding(16)
            .glassPanel(cornerRadius: 18)
            .frame(maxWidth: 620)

            Spacer(minLength: 0)
        }
    }

    private var gameView: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                pill(icon: "bolt.fill", label: "\(lm.t("score")): \(vm.correctCount)")
                Spacer()
                timerBadge
            }

            Spacer(minLength: 4)

            if let _ = vm.current {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble.fill")
                            .foregroundStyle(Color.glassCyan)
                        Text(lm.t("translation"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white.opacity(0.62))
                    }

                    Text(vm.prompt)
                        .font(.system(size: 44, weight: .medium, design: .default))
                        .minimumScaleFactor(0.34)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 14)
                .glassPanel(cornerRadius: 20, edgeHighlight: Color.white.opacity(0.16))

                if vm.showWrongAnswer {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(vm.target)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .glassPanel(cornerRadius: 14, edgeHighlight: Color.red.opacity(0.35))
                    .frame(maxWidth: 700)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "keyboard.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.glassCyan)

                        TextField(lm.t("enter_answer"), text: $vm.answer)
                            .textFieldStyle(.plain)
                            .font(.system(size: 25, weight: .medium, design: .default))
                            .foregroundColor(.white)
                            .focused($isFocused)
                            .onSubmit { checkAnswer() }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .glassPanel(cornerRadius: 16)
                    .frame(maxWidth: 700)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var timerBadge: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 6)

            Circle()
                .trim(from: 0, to: CGFloat(vm.timeLeft) / 60.0)
                .stroke(
                    LinearGradient(colors: [.glassCyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.glassCyan.opacity(0.35), radius: 8, x: 0, y: 4)
                .animation(.linear(duration: 1), value: vm.timeLeft)

            VStack(spacing: 2) {
                Text("\(vm.timeLeft)")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                Text("s")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 78, height: 78)
        .padding(6)
        .glassPanel(cornerRadius: 16, edgeHighlight: Color.glassCyan.opacity(0.24))
    }

    private func pill(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.glassCyan)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.88))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        )
    }

    private var speedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.2),
                    Color(red: 0.02, green: 0.03, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.glassCyan.opacity(0.18), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.blue.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 60,
                endRadius: 620
            )
            .ignoresSafeArea()
        }
    }

    private func checkAnswer() {
        vm.checkAnswer(
            onSuccess: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    vm.feedbackColor = .clear
                    vm.nextWord()
                    isFocused = true
                }
            },
            onFailure: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    vm.showWrongAnswer = false
                    vm.feedbackColor = .clear
                    vm.answer = ""
                    vm.nextWord()
                    isFocused = true
                }
            }
        )
    }
}
