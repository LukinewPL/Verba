import SwiftUI

struct SpeedRoundStartSection: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var vm: SpeedRoundViewModel
    let onStart: () -> Void

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.glassMint.opacity(0.5), Color.glassSky.opacity(0.18), .clear],
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
                                .stroke(Color.glassTeal.opacity(0.45), lineWidth: 1.2)
                        )

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.glassTeal)
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
                    SpeedRoundPill(icon: "trophy.fill", label: "\(lm.t("record")): \(vm.set.bestScore)")
                    SpeedRoundPill(icon: "timer", label: "60s")
                    SpeedRoundPill(icon: "text.book.closed.fill", label: "\(vm.set.words.count) \(lm.t("words"))")
                }
                .frame(maxWidth: .infinity)

                Button(action: onStart) {
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
                            colors: [Color.glassMint.opacity(0.95), Color.glassSky.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: Color.glassTeal.opacity(0.22), radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
                .pressAnimation()
            }
            .padding(18)
            .glassPanel(cornerRadius: 20, edgeHighlight: Color.glassTeal.opacity(0.2))
            .frame(maxWidth: 760)

            Spacer(minLength: 0)
        }
    }
}

struct SpeedRoundFinishedSection: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var vm: SpeedRoundViewModel
    let onDone: () -> Void

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Text(lm.t("time_up"))
                    .font(.system(size: 30, weight: .medium, design: .default))
                    .foregroundColor(.white)

                if vm.showRecordBlast {
                    Text("🏆 \(lm.t("new_record"))!")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }

                Text("\(lm.t("score")): \(vm.correctCount)")
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundColor(.glassTeal)

                Button(lm.t("done"), action: onDone)
                    .buttonStyle(GlassButtonStyle())
            }
            .padding(16)
            .glassPanel(cornerRadius: 18)
            .frame(maxWidth: 620)

            Spacer(minLength: 0)
        }
    }
}

struct SpeedRoundGameSection: View {
    @Environment(LanguageManager.self) private var lm
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @Bindable var vm: SpeedRoundViewModel
    let focusBinding: FocusState<Bool>.Binding
    let onSubmitAnswer: () -> Void
    private let timerOverlayHeight: CGFloat = 108

    var body: some View {
        VStack(spacing: 12) {
            Color.clear
                .frame(height: timerOverlayHeight)

            Spacer(minLength: 4)

            if vm.current != nil {
                ZStack {
                    promptCard
                        .id(vm.current?.id)
                        .transition(contentTransition(edge: .trailing))
                }
                .animation(contentAnimation, value: vm.current?.id)

                ZStack {
                    if vm.showWrongAnswer {
                        wrongAnswerCard
                            .transition(contentTransition(edge: .top))
                    } else {
                        answerField
                            .transition(contentTransition(edge: .bottom))
                    }
                }
                .animation(contentAnimation, value: vm.showWrongAnswer)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .top) {
            HStack(alignment: .top) {
                SpeedRoundPill(icon: "bolt.fill", label: "\(lm.t("score")): \(vm.correctCount)")
                Spacer(minLength: 18)
                SpeedRoundTimerBadge(timeLeft: vm.timeLeft)
            }
            .padding(.top, 2)
        }
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(Color.glassTeal)
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
    }

    private var wrongAnswerCard: some View {
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
    }

    private var answerField: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.glassTeal)

            TextField(lm.t("enter_answer"), text: $vm.answer)
                .textFieldStyle(.plain)
                .font(.system(size: 25, weight: .medium, design: .default))
                .foregroundColor(.white)
                .focused(focusBinding)
                .onSubmit {
                    onSubmitAnswer()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .glassPanel(cornerRadius: 16)
        .frame(maxWidth: 700)
    }

    private var contentAnimation: SwiftUI.Animation? {
        animationSpeed > 0 ? .spring(response: 0.34 / animationSpeed, dampingFraction: 0.82) : nil
    }

    private func contentTransition(edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        )
    }
}

private struct SpeedRoundTimerBadge: View {
    let timeLeft: Int
    private let progressLineWidth: CGFloat = 9
    private let badgeSize: CGFloat = 104

    private var progress: CGFloat {
        speedRoundTimerProgress(timeLeft: timeLeft)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.16), Color.white.opacity(0.055), Color.clear],
                        center: UnitPoint(x: 0.42, y: 0.34),
                        startRadius: 6,
                        endRadius: 72
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1.1)
                )
                .overlay(
                    Circle()
                        .inset(by: 11)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)

            Circle()
                .stroke(Color.white.opacity(0.09), lineWidth: progressLineWidth)
                .padding(8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.glassMint,
                            Color.glassMint.opacity(0.96),
                            Color.glassSky,
                            Color.glassTeal
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: progressLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(8)
                .shadow(color: Color.glassTeal.opacity(0.3), radius: 9, x: 0, y: 4)
                .animation(.linear(duration: 1), value: timeLeft)

            timerLabel
        }
        .frame(width: badgeSize, height: badgeSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(speedRoundTimerLabel(timeLeft: timeLeft))
    }

    private var timerLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(max(timeLeft, 0))")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("s")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .baselineOffset(1)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.16), radius: 2, x: 0, y: 1)
    }
}

func speedRoundTimerLabel(timeLeft: Int) -> String {
    "\(max(timeLeft, 0))s"
}

func speedRoundTimerProgress(timeLeft: Int, totalTime: Int = 60) -> CGFloat {
    guard totalTime > 0 else { return 0 }
    let clamped = min(max(timeLeft, 0), totalTime)
    return CGFloat(clamped) / CGFloat(totalTime)
}

private struct SpeedRoundPill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.glassTeal)
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
}
