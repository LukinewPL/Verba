import SwiftUI

struct TestQuestionView: View {
    @Environment(LanguageManager.self) private var lm
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @Bindable var vm: TestViewModel
    let openAnswerFocus: FocusState<Bool>.Binding
    let onExitRequested: () -> Void
    let onRequestFocus: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onExitRequested) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(vm.currentIdx + 1) / \(max(1, vm.queue.count))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.75))

                Spacer()

                TestStatChip(icon: "bolt.fill", label: "\(lm.t("score")): \(vm.score)")
            }

            TestProgressTrack(currentIndex: vm.currentIdx, totalCount: vm.queue.count)

            if vm.current != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble.fill")
                            .foregroundStyle(Color.glassCyan)
                        Text(lm.t("translation"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white.opacity(0.62))
                    }

                    Text(vm.prompt)
                        .font(.system(size: 42, weight: .medium, design: .default))
                        .minimumScaleFactor(0.35)
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 14)
                .glassPanel(cornerRadius: 20, edgeHighlight: Color.white.opacity(0.16))
                .padding(.top, 2)

                if vm.isMultipleChoice {
                    VStack(spacing: 8) {
                        ForEach(Array(vm.mcOptions.enumerated()), id: \.offset) { index, option in
                            Button(action: { vm.submitMC(option) }) {
                                HStack(spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.65))
                                        .frame(width: 34, alignment: .leading)

                                    Text(option)
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(optionBackground(for: option))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(vm.selectedOption == option ? 1.02 : 1)
                            .animation(animationSpeed > 0 ? .spring(response: 0.28, dampingFraction: 0.82) : nil, value: vm.selectedOption)
                            .disabled(vm.selectedOption != nil)
                        }
                    }
                    .frame(maxWidth: 820)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "keyboard.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.glassCyan)

                        TextField(lm.t("enter_answer"), text: $vm.answer)
                            .textFieldStyle(.plain)
                            .font(.system(size: 25, weight: .medium, design: .default))
                            .foregroundColor(.white)
                            .focused(openAnswerFocus)
                            .onSubmit { vm.submitOpen() }
                            .disabled(vm.selectedOption != nil)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .glassPanel(cornerRadius: 16)
                    .frame(maxWidth: 820)

                    if vm.showCorrectAnswer {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(vm.target)
                                .font(.system(size: 22, weight: .medium, design: .default))
                                .foregroundColor(.glassCyan)
                        }
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeInOut(duration: 0.2), value: vm.showCorrectAnswer)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 10)
        .onAppear(perform: onRequestFocus)
    }

    private func optionBackground(for option: String) -> LinearGradient {
        if let selected = vm.selectedOption {
            if option == vm.target {
                return LinearGradient(colors: [Color.green.opacity(0.55), Color.green.opacity(0.32)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if option == selected {
                return LinearGradient(colors: [Color.red.opacity(0.6), Color.red.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        return LinearGradient(
            colors: [Color.white.opacity(0.11), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct TestProgressTrack: View {
    let currentIndex: Int
    let totalCount: Int

    var body: some View {
        GeometryReader { proxy in
            let total = max(1, totalCount)
            let progress = CGFloat(currentIndex + 1) / CGFloat(total)
            let filled = max(8, proxy.size.width * progress)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.glassCyan, Color.blue.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: filled)
                    .shadow(color: Color.glassCyan.opacity(0.35), radius: 8, x: 0, y: 2)
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.26), value: currentIndex)
    }
}
