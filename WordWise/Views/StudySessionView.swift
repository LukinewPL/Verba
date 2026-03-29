import SwiftUI; import SwiftData

private enum HintAnimationPhase {
    case hidden
    case showcase
    case flying
    case inline
}

private enum HintFrameID: String {
    case root
    case slot
}

private let hintCoordinateSpaceName = "StudyHintCoordinateSpace"

private struct HintFramePreferenceKey: PreferenceKey {
    static var defaultValue: [HintFrameID: CGRect] = [:]
    
    static func reduce(value: inout [HintFrameID: CGRect], nextValue: () -> [HintFrameID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension View {
    func captureHintFrame(_ id: HintFrameID) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: HintFramePreferenceKey.self,
                        value: [id: proxy.frame(in: .named(hintCoordinateSpaceName))]
                    )
            }
        )
    }
}

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
    
    init(set: WordSet) {
        _vm = State(initialValue: StudySessionViewModel(set: set))
    }
    
    var body: some View {
        VStack {
            Spacer()
            if let _ = vm.current {
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
                            .foregroundColor(.yellow)
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
                    Text(lm.t("done")).font(.largeTitle).foregroundColor(.white)
                    Button(lm.t("finish")) { dismiss() }.buttonStyle(GlassButtonStyle())
                }
            }
            Spacer()
        }
        .captureHintFrame(.root)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: hintCoordinateSpaceName)
        .background(vm.feedback.opacity(0.3).ignoresSafeArea())
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
            vm.setup(repository: repository)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
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
                            .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
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
            
            ZStack(alignment: .leading) {
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
                    .foregroundColor(.glassCyan)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(height: 58)
        .padding(.top, 10)
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
        
        AudioFeedback.shared.playHintReveal()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            particlesActive = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                flyingStrongGlow = false
                withAnimation(.timingCurve(0.14, 0.93, 0.2, 1, duration: 0.44)) {
                    flyingHintPosition = destination
                    flyingHintScale = 0.165
                    flyingHintRotation = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
                    hintPhase = .inline
                    withAnimation(.easeInOut(duration: 0.22)) {
                        inlineHintOpacity = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
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
        // Tune destination toward optical center of the glyph in the slot.
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                    vm.answer = ""
                    vm.nextWord()
                    vm.feedback = .clear
                    isFocused = true
                }
            },
            onFailure: {
                triggerWrongVapor(from: vm.answer)
                vm.answer = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    vm.nextWord()
                    vm.feedback = .clear
                    isFocused = true
                }
            }
        )
    }
    
    private func triggerWrongVapor(from text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        wrongVaporText = text
        wrongVaporOpacity = 1
        wrongVaporYOffset = 0
        wrongVaporScale = 1
        wrongVaporBurstID += 1
        
        // Start fade on the next run loop tick so the initial "puff" frame is always visible.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.78)) {
                wrongVaporOpacity = 0
                wrongVaporYOffset = -42
                wrongVaporScale = 1.16
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.84) {
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
        AudioFeedback.shared.playHintVapor()
        
        withAnimation(.easeIn(duration: 0.22)) {
            fadingSlotHintOpacity = 0
            fadingSlotHintScale = 0.01
        }
        
        withAnimation(.easeOut(duration: 0.58)) {
            slotVaporOpacity = 0
            slotVaporYOffset = -10
            slotVaporScale = 1.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            fadingSlotHintLetter = ""
        }
    }
}

private struct WrongAnswerVapor: View {
    let text: String
    let opacity: Double
    let yOffset: CGFloat
    let scale: CGFloat
    let trigger: Int
    @State private var steamExpanded = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Strong initial "puff" cloud.
            ForEach(0..<3, id: \.self) { index in
                let x = CGFloat(index) * 34 + 28
                let size: CGFloat = index == 1 ? 72 : 58
                
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: size, height: size)
                    .blur(radius: steamExpanded ? 10 : 3)
                    .scaleEffect(steamExpanded ? 1.22 : 0.72)
                    .offset(x: x, y: yOffset - (steamExpanded ? 10 : 0))
                    .opacity(opacity * (steamExpanded ? 0.24 : 0.72))
            }
            
            Text(text)
                .font(.title.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), Color(red: 0.78, green: 0.92, blue: 1.0).opacity(0.62)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.7), radius: 5, x: 0, y: 0)
                .blur(radius: steamExpanded ? 2.5 : 0.15)
                .scaleEffect(scale)
                .offset(y: yOffset)
                .opacity(opacity)
            
            // Quick "puff" burst.
            ForEach(0..<34, id: \.self) { index in
                let startX = 18 + CGFloat(seed(index, salt: 3) * 126)
                let driftX = (CGFloat(seed(index, salt: 19)) - 0.5) * 74
                let driftY = 4 + CGFloat(seed(index, salt: 31) * 40)
                let size = CGFloat(5 + seed(index, salt: 47) * 11)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.92),
                                Color(red: 0.74, green: 0.88, blue: 1.0).opacity(0.45),
                                Color.white.opacity(0.01)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .frame(width: size, height: size)
                    .offset(
                        x: startX + (steamExpanded ? driftX : 0),
                        y: yOffset - (steamExpanded ? driftY : 0)
                    )
                    .opacity(opacity * (steamExpanded ? 0.45 : 0.96))
                    .blur(radius: steamExpanded ? 3.2 : 0.6)
            }
            
            // Steam streaks.
            ForEach(0..<18, id: \.self) { index in
                let startX = 16 + CGFloat(seed(index, salt: 61) * 124)
                let driftX = (CGFloat(seed(index, salt: 71)) - 0.5) * 32
                let rise = 16 + CGFloat(seed(index, salt: 83) * 30)
                let width = CGFloat(3 + seed(index, salt: 97) * 4)
                let height = CGFloat(16 + seed(index, salt: 109) * 18)
                
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: width, height: height)
                    .blur(radius: 2)
                    .offset(
                        x: startX + (steamExpanded ? driftX : 0),
                        y: yOffset - (steamExpanded ? rise : 4)
                    )
                    .opacity(opacity * (steamExpanded ? 0.24 : 0.45))
            }
        }
        .allowsHitTesting(false)
        .onAppear { runSteam() }
        .onChange(of: trigger) { _, _ in runSteam() }
    }
    
    private func runSteam() {
        steamExpanded = false
        DispatchQueue.main.async {
            steamExpanded = true
        }
    }
    
    private func seed(_ index: Int, salt: Int) -> Double {
        let raw = sin(Double(index * 79 + salt * 41 + trigger * 17) * 12.9898) * 43758.5453
        return raw - floor(raw)
    }
}

private struct SlotHintVapor: View {
    let opacity: Double
    let yOffset: CGFloat
    let scale: CGFloat
    let trigger: Int
    
    var body: some View {
        let progress = max(0, min(1.2, (scale - 1) / 0.95))
        
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            
            ZStack {
                // Base mist that covers the whole slot area.
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.01)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(width, height) * 0.9
                        )
                    )
                    .scaleEffect(1 + progress * 0.1)
                    .offset(y: yOffset * 0.35)
                    .opacity(opacity * (0.78 - 0.22 * progress))
                    .blur(radius: 1.6 + 2.4 * progress)
                
                // Dense particles distributed across the full slot.
                ForEach(0..<96, id: \.self) { index in
                    let baseX = (CGFloat(seed(index, salt: 13)) - 0.5) * width * 0.9
                    let baseY = (CGFloat(seed(index, salt: 29)) - 0.5) * height * 0.9
                    let driftX = (CGFloat(seed(index, salt: 43)) - 0.5) * (8 + 26 * progress)
                    let driftY = (CGFloat(seed(index, salt: 59)) - 0.5) * (8 + 26 * progress)
                    let size = CGFloat(2.2 + seed(index, salt: 71) * 4.1)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.96), Color.white.opacity(0.08)],
                                center: .center,
                                startRadius: 0,
                                endRadius: size
                            )
                        )
                        .frame(width: size, height: size)
                        .offset(
                            x: baseX + driftX,
                            y: yOffset + baseY + driftY
                        )
                        .opacity(opacity * (0.62 + 0.16 * (1 - progress)))
                        .blur(radius: (1.0 + 1.9 * progress) * scale)
                }
                
                // Center plume for a stronger "puff" effect.
                ForEach(0..<4, id: \.self) { idx in
                    let cloudSize: CGFloat = idx == 1 ? 36 : (idx == 2 ? 32 : 28)
                    let cloudX: CGFloat = idx == 0 ? -8 : (idx == 1 ? 0 : (idx == 2 ? 8 : 2))
                    let cloudY: CGFloat = idx == 3 ? 8 : (idx == 1 ? -2 : 2)
                    
                    Circle()
                        .fill(Color.white.opacity(0.84))
                        .frame(width: cloudSize, height: cloudSize)
                        .scaleEffect(scale)
                        .offset(
                            x: cloudX * (1 + progress * 0.45),
                            y: yOffset + cloudY + (idx == 3 ? 6 : -8 * progress)
                        )
                        .opacity(opacity * 0.68)
                        .blur(radius: 2.4 * scale)
                }
            }
            .frame(width: width, height: height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
    
    private func seed(_ index: Int, salt: Int) -> Double {
        let raw = sin(Double(index * 83 + salt * 37 + trigger * 19) * 12.9898) * 43758.5453
        return raw - floor(raw)
    }
}

private struct GoldenHintLetter: View {
    let letter: String
    let fontSize: CGFloat
    let strongGlow: Bool
    
    var body: some View {
        let goldenGradient = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.98, blue: 0.85),
                Color(red: 1.0, green: 0.86, blue: 0.42),
                Color(red: 0.95, green: 0.68, blue: 0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        Text(letter)
            .font(.system(size: fontSize, weight: .medium, design: .default))
            .foregroundStyle(goldenGradient)
            .shadow(color: Color.yellow.opacity(strongGlow ? 0.95 : 0.5), radius: strongGlow ? 30 : 10, x: 0, y: 0)
            .shadow(color: Color.orange.opacity(strongGlow ? 0.6 : 0.25), radius: strongGlow ? 60 : 16, x: 0, y: 0)
            .overlay(
                Text(letter)
                    .font(.system(size: fontSize, weight: .medium, design: .default))
                    .foregroundStyle(Color.white.opacity(strongGlow ? 0.35 : 0.12))
                    .blur(radius: strongGlow ? 1 : 0)
            )
    }
}

private struct GoldenParticleBurst: View {
    let trigger: Int
    @State private var expanded = false
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Core burst around the center letter.
            ForEach(0..<110, id: \.self) { index in
                    let angle = Double(index) * 137.508 * .pi / 180
                    let nearRadius: CGFloat = 10 + CGFloat((index % 4) * 7)
                    let farRadius: CGFloat = 130 + CGFloat((index % 7) * 16) + CGFloat((index % 3) * 20)
                    let size: CGFloat = CGFloat(2 + (index % 5))
                    let delay = Double(index) * 0.0035
                    
                    Circle()
                        .fill(index.isMultiple(of: 2) ? Color.yellow.opacity(0.98) : Color.orange.opacity(0.9))
                        .frame(width: size, height: size)
                        .offset(
                            x: CGFloat(cos(angle)) * (expanded ? farRadius : nearRadius),
                            y: CGFloat(sin(angle)) * (expanded ? farRadius : nearRadius)
                        )
                        .opacity(expanded ? 0 : 0.95)
                        .scaleEffect(expanded ? 0.28 : 1.45)
                        .animation(.easeOut(duration: 1.4).delay(delay), value: expanded)
                }
                
                // Full-screen shimmer particles.
            ForEach(0..<260, id: \.self) { index in
                    let x = CGFloat(seed(index, salt: 11)) * proxy.size.width
                    let y = CGFloat(seed(index, salt: 37)) * proxy.size.height
                    let driftX = (CGFloat(seed(index, salt: 73)) - 0.5) * 120
                    let driftY = (CGFloat(seed(index, salt: 97)) - 0.5) * 120
                    let size = CGFloat(1.5 + seed(index, salt: 131) * 3.2)
                    let delay = seed(index, salt: 181) * 0.28
                    
                    Circle()
                        .fill(index.isMultiple(of: 3) ? Color.yellow.opacity(0.92) : Color.orange.opacity(0.72))
                        .frame(width: size, height: size)
                        .position(
                            x: x + (expanded ? driftX : 0),
                            y: y + (expanded ? driftY : 0)
                        )
                        .opacity(expanded ? 0 : 0.9)
                        .scaleEffect(expanded ? 0.5 : 1.2)
                        .animation(.easeOut(duration: 1.9).delay(delay), value: expanded)
                }
                
            ForEach(0..<90, id: \.self) { index in
                    let x = CGFloat(seed(index, salt: 211)) * proxy.size.width
                    let y = CGFloat(seed(index, salt: 241)) * proxy.size.height
                    let glowSize = CGFloat(6 + seed(index, salt: 271) * 10)
                    let delay = seed(index, salt: 307) * 0.32
                    
                    Circle()
                        .fill(Color.yellow.opacity(0.14))
                        .frame(width: glowSize, height: glowSize)
                        .blur(radius: 2.4)
                        .position(x: x, y: y)
                        .opacity(expanded ? 0 : 0.85)
                        .animation(.easeOut(duration: 2.1).delay(delay), value: expanded)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onAppear { runBurst() }
        .onChange(of: trigger) { _, _ in runBurst() }
    }
    
    private func runBurst() {
        expanded = false
        DispatchQueue.main.async {
            expanded = true
        }
    }
    
    private func seed(_ index: Int, salt: Int) -> Double {
        let raw = sin(Double(index * 97 + salt * 53 + trigger * 31) * 12.9898) * 43758.5453
        return raw - floor(raw)
    }
}
