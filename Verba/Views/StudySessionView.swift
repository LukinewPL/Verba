import SwiftUI

struct StudySessionView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @Environment(AppCoordinator.self) private var coordinator
    @State private var vm: StudySessionViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var hintPhase: HintAnimationPhase = .hidden
    @State private var hintBurstID: Int = 0
    @State private var capturedFrames: [HintFrameID: CGRect] = [:]
    @State private var flyingHintPosition: CGPoint = .zero
    @State private var flyingHintScale: CGFloat = 1
    @State private var flyingHintOpacity: Double = 0
    @State private var flyingHintRotation: Double = 0
    @State private var flyingStrongGlow = true
    @State private var inlineHintOpacity: Double = 0
    @State private var particlesActive = false
    @State private var particlesOpacity: Double = 0
    @State private var wrongVaporText = ""
    @State private var wrongVaporOpacity: Double = 0
    @State private var wrongVaporYOffset: CGFloat = 0
    @State private var wrongVaporScale: CGFloat = 1
    @State private var wrongVaporBurstID: Int = 0
    @State private var slotVaporOpacity: Double = 0
    @State private var slotVaporYOffset: CGFloat = 0
    @State private var slotVaporScale: CGFloat = 1
    @State private var slotVaporBurstID: Int = 0
    @State private var fadingSlotHintLetter = ""
    @State private var fadingSlotHintOpacity: Double = 0
    @State private var fadingSlotHintScale: CGFloat = 1
    @State private var hintTasks: [Task<Void, Never>] = []
    @State private var answerTasks: [Task<Void, Never>] = []
    @State private var appearFocusTask: Task<Void, Never>?
    @State private var showRestartPrompt = false

    init(set: WordSet) {
        _vm = State(initialValue: StudySessionViewModel(set: set))
    }

    var body: some View {
        VStack {
            Spacer()
            if showRestartPrompt {
                restartPromptSection
            } else if vm.current != nil {
                Text(vm.prompt)
                    .font(.system(size: 64, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .premiumGlass()
                    .padding()

                HStack(spacing: 12) {
                    answerInput

                    Button(action: { triggerHint() }) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundColor(.glassMint)
                            .padding()
                            .premiumGlass()
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.feedback != .clear || vm.hasTypedFirstTargetLetter || !vm.hint.isEmpty || hintPhase != .hidden)
                }
                .frame(maxWidth: 650)
                .padding(.horizontal, 40)

                feedbackArea
            } else {
                VStack(spacing: 20) {
                    Text(lm.t("done"))
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Button(lm.t("finish")) { dismiss() }
                        .buttonStyle(GlassButtonStyle())
                }
            }
            Spacer()
        }
        .captureHintFrame(.root)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: hintCoordinateSpaceName)
        .background {
            if vm.feedback != .clear {
                DesignSystem.Feedback.gradient(isSuccess: vm.feedbackIsSuccess)
                    .opacity(0.28)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.feedback)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .overlay {
            if hintPhase == .showcase || hintPhase == .flying || flyingHintOpacity > 0.001 || particlesActive {
                hintAnimationOverlay
            }
        }
        .onPreferenceChange(HintFramePreferenceKey.self) { frames in
            capturedFrames = frames
        }
        .onAppear {
            coordinator.enterFocusedMode()
            prepareInitialState()
        }
        .onChange(of: vm.hint) { _, newValue in
            if newValue.isEmpty {
                hintPhase = .hidden
                flyingHintOpacity = 0
                inlineHintOpacity = 0
                particlesActive = false
                particlesOpacity = 0
            }
        }
        .onDisappear {
            appearFocusTask?.cancel()
            appearFocusTask = nil
            cancelHintTasks()
            cancelAnswerTasks()
            coordinator.exitFocusedMode()
            vm.saveSession()
        }
    }

    private var answerInput: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.glassSky.opacity(0.32), lineWidth: 1)
                    )

                if vm.shouldShowInlineHint && hintPhase == .inline {
                    GoldenHintLetter(letter: vm.hint, fontSize: 40, strongGlow: false)
                        .offset(y: inlineHintYOffset(vm.hint))
                        .opacity(inlineHintOpacity)
                }

                if !fadingSlotHintLetter.isEmpty && fadingSlotHintOpacity > 0.001 {
                    GoldenHintLetter(letter: fadingSlotHintLetter, fontSize: 40, strongGlow: false)
                        .offset(y: inlineHintYOffset(fadingSlotHintLetter))
                        .scaleEffect(fadingSlotHintScale)
                        .opacity(fadingSlotHintOpacity)
                        .blur(radius: (1 - fadingSlotHintOpacity) * 7)
                }

                if slotVaporOpacity > 0.001 {
                    SlotHintVapor(
                        opacity: slotVaporOpacity,
                        yOffset: slotVaporYOffset,
                        scale: slotVaporScale,
                        trigger: slotVaporBurstID
                    )
                }
            }
            .frame(width: 52, height: 52)
            .captureHintFrame(.slot)

            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 1, height: 34)

            TextField(
                "",
                text: $vm.answer,
                prompt: Text(lm.t("enter_answer"))
                    .foregroundStyle(.white.opacity(0.5))
            )
            .textFieldStyle(.plain)
            .font(.title)
            .focused($isFocused)
            .onSubmit { checkAnswer() }
            .disabled(vm.feedback != .clear)
        }
        .padding(.horizontal, 12)
        .frame(height: 76)
        .premiumGlass()
        .overlay(alignment: .leading) {
            if !wrongVaporText.isEmpty {
                WrongAnswerVapor(
                    text: wrongVaporText,
                    opacity: wrongVaporOpacity,
                    yOffset: wrongVaporYOffset,
                    scale: wrongVaporScale,
                    trigger: wrongVaporBurstID
                )
                .offset(x: 84)
                .allowsHitTesting(false)
            }
        }
    }

    private var feedbackArea: some View {
        ZStack {
            if vm.feedback == .red {
                Text(vm.target)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(height: 58)
        .padding(.top, 10)
    }

    private var restartPromptSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(.glassMint)

            Text(lm.t("study_restart_title"))
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(lm.t("study_restart_message"))
                .font(.body)
                .foregroundColor(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)

            HStack(spacing: 10) {
                Button(lm.t("study_restart_cancel")) {
                    dismiss()
                }
                .buttonStyle(GlassButtonStyle())

                Button(lm.t("study_restart_confirm")) {
                    startFromBeginning()
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }

    private var hintAnimationOverlay: some View {
        ZStack {
            if hintPhase == .showcase {
                Color.black.opacity(0.26)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if particlesActive {
                GoldenParticleBurst(trigger: hintBurstID)
                    .opacity(particlesOpacity)
                    .animation(.easeOut(duration: 1.4), value: particlesOpacity)
            }

            GoldenHintLetter(letter: vm.hint, fontSize: 250, strongGlow: flyingStrongGlow)
                .frame(width: 280, height: 280)
                .scaleEffect(flyingHintScale)
                .rotationEffect(.degrees(flyingHintRotation))
                .opacity(flyingHintOpacity)
                .position(flyingHintPosition)
        }
        .allowsHitTesting(false)
    }

    private func triggerHint() {
        guard vm.feedback == .clear else { return }
        guard !vm.hasTypedFirstTargetLetter else { return }
        guard vm.hint.isEmpty else { return }

        vm.provideHint()
        guard !vm.hint.isEmpty else { return }

        vm.playHintRevealFeedback()
        cancelHintTasks()
        hintBurstID += 1
        particlesActive = true
        particlesOpacity = 1

        flyingHintPosition = rootCenterPoint
        flyingHintScale = 1
        flyingHintOpacity = 1
        flyingHintRotation = 0
        flyingStrongGlow = true
        inlineHintOpacity = 0
        hintPhase = .showcase

        withAnimation(.easeOut(duration: 2.6)) {
            particlesOpacity = 0
        }
        scheduleHint(after: 2.7) {
            particlesActive = false
        }

        scheduleHint(after: 0.5) {
            hintPhase = .flying
            let start = rootCenterPoint
            let destination = slotPoint(for: vm.hint)
            let arcMid = CGPoint(
                x: ((start.x + destination.x) / 2) + 30,
                y: min(start.y, destination.y) - 120
            )

            withAnimation(.timingCurve(0.2, 0.92, 0.28, 1, duration: 0.22)) {
                flyingHintPosition = arcMid
                flyingHintScale = 0.56
                flyingHintRotation = 8
            }

            scheduleHint(after: 0.22) {
                flyingStrongGlow = false
                withAnimation(.timingCurve(0.14, 0.93, 0.2, 1, duration: 0.44)) {
                    flyingHintPosition = destination
                    flyingHintScale = 0.165
                    flyingHintRotation = 0
                }

                scheduleHint(after: 0.46) {
                    hintPhase = .inline
                    withAnimation(.easeInOut(duration: 0.22)) {
                        inlineHintOpacity = 1
                    }
                    scheduleHint(after: 0.22) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            flyingHintOpacity = 0
                        }
                    }
                }
            }
        }
    }

    private var rootCenterPoint: CGPoint {
        guard let root = capturedFrames[.root], root.width > 0, root.height > 0 else {
            return CGPoint(x: 600, y: 380)
        }
        return CGPoint(x: root.midX, y: root.midY)
    }

    private func slotPoint(for letter: String) -> CGPoint {
        guard let slot = capturedFrames[.slot] else {
            return CGPoint(x: 190, y: 430)
        }

        return CGPoint(
            x: slot.midX - 1,
            y: slot.midY + inlineHintYOffset(letter)
        )
    }

    private func inlineHintYOffset(_ letter: String) -> CGFloat {
        guard let ch = letter.lowercased().first else { return -2 }
        if ch == "j" { return -4 }
        let descenders = "gjpqy"
        return descenders.contains(ch) ? -5 : -2
    }

    private func checkAnswer() {
        if hintPhase == .inline, !vm.hint.isEmpty {
            triggerSlotHintDisappear(letter: vm.hint)
            hintPhase = .hidden
            inlineHintOpacity = 0
        }

        vm.checkAnswer(
            onSuccess: {
                cancelAnswerTasks()
                scheduleAnswer(after: 0.42) {
                    vm.answer = ""
                    vm.nextWord()
                    vm.feedback = .clear
                    handlePostAnswerAdvance()
                }
            },
            onFailure: {
                triggerWrongVapor(from: vm.answer)
                vm.answer = ""
                cancelAnswerTasks()
                scheduleAnswer(after: 1.5) {
                    vm.nextWord()
                    vm.feedback = .clear
                    handlePostAnswerAdvance()
                }
            }
        )
    }

    private func prepareInitialState() {
        vm.setup(repository: repository)
        if vm.hasFullyLearnedSet {
            showRestartPrompt = true
            return
        }
        showRestartPrompt = false
        vm.startSession()
        focusAnswerField()
    }

    private func startFromBeginning() {
        vm.restartLearningFromBeginning()
        showRestartPrompt = false
        focusAnswerField()
    }

    private func handlePostAnswerAdvance() {
        if vm.current == nil && vm.hasFullyLearnedSet {
            showRestartPrompt = true
            isFocused = false
            return
        }
        showRestartPrompt = false
        isFocused = true
    }

    private func focusAnswerField() {
        appearFocusTask?.cancel()
        appearFocusTask = schedule(after: 0.5) {
            isFocused = true
        }
    }

    private func triggerWrongVapor(from text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        wrongVaporText = text
        wrongVaporOpacity = 1
        wrongVaporYOffset = 0
        wrongVaporScale = 1
        wrongVaporBurstID += 1

        withAnimation(.easeOut(duration: 0.78)) {
            wrongVaporOpacity = 0
            wrongVaporYOffset = -42
            wrongVaporScale = 1.16
        }

        scheduleAnswer(after: 0.84) {
            wrongVaporText = ""
        }
    }

    private func triggerSlotHintDisappear(letter: String) {
        fadingSlotHintLetter = letter
        fadingSlotHintOpacity = 1
        fadingSlotHintScale = 1

        slotVaporOpacity = 1
        slotVaporYOffset = 0
        slotVaporScale = 1
        slotVaporBurstID += 1
        vm.playHintVaporFeedback()

        withAnimation(.easeIn(duration: 0.22)) {
            fadingSlotHintOpacity = 0
            fadingSlotHintScale = 0.01
        }

        withAnimation(.easeOut(duration: 0.58)) {
            slotVaporOpacity = 0
            slotVaporYOffset = -10
            slotVaporScale = 1.95
        }

        scheduleHint(after: 0.24) {
            fadingSlotHintLetter = ""
        }
    }

    @discardableResult
    private func schedule(after seconds: Double, action: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            let delay = UInt64(max(0, seconds) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            action()
        }
    }

    private func scheduleHint(after seconds: Double, action: @escaping @MainActor () -> Void) {
        hintTasks.append(schedule(after: seconds, action: action))
    }

    private func scheduleAnswer(after seconds: Double, action: @escaping @MainActor () -> Void) {
        answerTasks.append(schedule(after: seconds, action: action))
    }

    private func cancelHintTasks() {
        hintTasks.forEach { $0.cancel() }
        hintTasks.removeAll()
    }

    private func cancelAnswerTasks() {
        answerTasks.forEach { $0.cancel() }
        answerTasks.removeAll()
    }
}
