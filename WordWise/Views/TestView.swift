import SwiftUI
import SwiftData

struct TestView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var vm: TestViewModel

    @Environment(WordRepository.self) private var repository
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @AppStorage("animationSpeed") var animationSpeed: Double = 1.0
    @State private var showExitConfirm = false
    @FocusState private var isOpenAnswerFocused: Bool

    init(set: WordSet) {
        self.set = set
        _vm = State(initialValue: TestViewModel(set: set))
    }

    var body: some View {
        ZStack {
            testBackground

            Group {
                if vm.isSetup {
                    setupView
                } else if vm.isFinished {
                    resultsView
                } else {
                    questionView
                }
            }
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .overlay {
            vm.feedbackColor.opacity(0.24)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            coordinator.enterFocusedMode()
            vm.setup(repository: repository, dismiss: { dismiss() })
            vm.reset()
        }
        .onChange(of: vm.currentIdx) { _, _ in
            requestOpenAnswerFocus()
        }
        .onChange(of: vm.isSetup) { _, _ in
            requestOpenAnswerFocus()
        }
        .onChange(of: vm.isMultipleChoice) { _, _ in
            requestOpenAnswerFocus()
        }
        .onDisappear {
            coordinator.exitFocusedMode()
            isOpenAnswerFocused = false
            vm.abandonTest()
        }
        .alert(lm.t("finish"), isPresented: $showExitConfirm) {
            Button(lm.t("cancel"), role: .cancel) { }
            Button(lm.t("finish"), role: .destructive) {
                vm.abandonTest()
                dismiss()
            }
        } message: {
            Text(lm.t("undone_msg"))
        }
        .navigationTitle(lm.t("test"))
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    private var setupView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.glassCyan.opacity(0.14))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.white, Color.glassCyan)
                    }
                        .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lm.t("test_setup"))
                            .font(.system(size: 26, weight: .medium, design: .default))
                            .foregroundColor(.white)
                        Text(set.name)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.62))
                            .lineLimit(1)
                    }

                    Spacer()

                    statChip(icon: "text.book.closed.fill", label: "\(set.words.count) \(lm.t("words"))")
                }
                .padding(14)
                .glassPanel(cornerRadius: 20, edgeHighlight: Color.glassCyan.opacity(0.2))

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(lm.t("questions"))
                                .font(.system(size: 18, weight: .medium, design: .default))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(vm.questionCount))")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundStyle(Color.glassCyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.glassCyan.opacity(0.2))
                                        .overlay(Capsule().stroke(Color.glassCyan.opacity(0.45), lineWidth: 1))
                                )
                        }

                        Slider(value: $vm.questionCount, in: 5...50, step: 5)
                            .tint(.glassCyan)

                        HStack {
                            Text("5")
                            Spacer()
                            Text("25")
                            Spacer()
                            Text("50")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(12)
                    .glassPanel(cornerRadius: 14, edgeHighlight: Color.white.opacity(0.14))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(lm.t("multiple_choice"))
                            .font(.system(size: 15, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.86))

                        HStack(spacing: 8) {
                            modeButton(
                                title: lm.t("multiple_choice"),
                                icon: "list.bullet.rectangle.portrait.fill",
                                isSelected: vm.isMultipleChoice,
                                action: { vm.isMultipleChoice = true }
                            )

                            modeButton(
                                title: lm.t("translation"),
                                icon: "keyboard.fill",
                                isSelected: !vm.isMultipleChoice,
                                action: { vm.isMultipleChoice = false }
                            )
                        }
                    }
                }
                .padding(14)
                .glassPanel(cornerRadius: 20)

                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        vm.startTest()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.headline.weight(.semibold))
                        Text(lm.t("start"))
                            .font(.system(size: 18, weight: .medium, design: .default))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
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
                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                    )
                    .shadow(color: Color.glassCyan.opacity(0.24), radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
                .pressAnimation()
            }
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
    }

    private var resultsView: some View {
        VStack(spacing: 14) {
            let percentage = Double(vm.score) / Double(max(1, vm.queue.count))

            VStack(spacing: 10) {
                Image(systemName: percentage >= 0.7 ? "trophy.fill" : "checkmark.seal.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(percentage >= 0.7 ? .yellow : .glassCyan)

                Text(lm.t("test_results"))
                    .font(.system(size: 30, weight: .medium, design: .default))
                    .foregroundColor(.white)

                Text("\(vm.score) / \(vm.queue.count)")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.72))
            }
            .padding(16)
            .glassPanel(cornerRadius: 20, edgeHighlight: Color.glassCyan.opacity(0.2))

            Text("\(Int(percentage * 100))%")
                .font(.system(size: 70, weight: .medium, design: .default))
                .foregroundColor(percentage >= 0.7 ? .green : (percentage >= 0.5 ? .orange : .red))

            if !vm.wrongAnswers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(lm.t("review_wrong"))
                        .font(.headline)
                        .foregroundColor(.glassCyan)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(0..<vm.wrongAnswers.count, id: \.self) { i in
                                HStack(spacing: 10) {
                                    Text(vm.wrongAnswers[i].0)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(vm.wrongAnswers[i].1)
                                        .foregroundColor(.glassCyan)
                                        .bold()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .glassPanel(cornerRadius: 14, edgeHighlight: Color.white.opacity(0.12))
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                }
                .padding(14)
                .glassPanel(cornerRadius: 16)
                .frame(maxWidth: 700)
            }

            Button(lm.t("finish")) { vm.finishTestAndSave() }
                .buttonStyle(GlassButtonStyle())
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var questionView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { showExitConfirm = true }) {
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

                statChip(icon: "bolt.fill", label: "\(lm.t("score")): \(vm.score)")
            }

            progressTrack

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
                        ForEach(Array(vm.mcOptions.enumerated()), id: \.element) { index, opt in
                            Button(action: { vm.submitMC(opt) }) {
                                HStack(spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.65))
                                        .frame(width: 34, alignment: .leading)

                                    Text(opt)
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(optionBackground(for: opt))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(vm.selectedOption == opt ? 1.02 : 1)
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
                            .focused($isOpenAnswerFocused)
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
        .onAppear {
            requestOpenAnswerFocus()
        }
    }

    private var progressTrack: some View {
        GeometryReader { proxy in
            let total = max(1, vm.queue.count)
            let progress = CGFloat(vm.currentIdx + 1) / CGFloat(total)
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
        .animation(.easeInOut(duration: 0.26), value: vm.currentIdx)
    }

    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.medium))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(colors: [Color.glassCyan.opacity(0.45), Color.blue.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.glassCyan.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func statChip(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.glassCyan)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.88))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
    }

    private func optionBackground(for opt: String) -> some ShapeStyle {
        if let selected = vm.selectedOption {
            if opt == vm.target {
                return LinearGradient(colors: [Color.green.opacity(0.55), Color.green.opacity(0.32)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if opt == selected {
                return LinearGradient(colors: [Color.red.opacity(0.6), Color.red.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        return LinearGradient(
            colors: [Color.white.opacity(0.11), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func requestOpenAnswerFocus() {
        guard !vm.isSetup, !vm.isFinished, !vm.isMultipleChoice else {
            isOpenAnswerFocused = false
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard !vm.isSetup, !vm.isFinished, !vm.isMultipleChoice, vm.selectedOption == nil else { return }
            isOpenAnswerFocused = true
        }
    }

    private var testBackground: some View {
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
                colors: [Color.glassCyan.opacity(0.2), .clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.blue.opacity(0.18), .clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }
}
