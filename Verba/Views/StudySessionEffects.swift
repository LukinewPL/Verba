import SwiftUI

enum HintAnimationPhase {
    case hidden
    case showcase
    case flying
    case inline
}

enum HintFrameID: String {
    case root
    case slot
}

let hintCoordinateSpaceName = "StudyHintCoordinateSpace"

struct HintFramePreferenceKey: PreferenceKey {
    static var defaultValue: [HintFrameID: CGRect] = [:]

    static func reduce(value: inout [HintFrameID: CGRect], nextValue: () -> [HintFrameID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
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

struct WrongAnswerVapor: View {
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
                        colors: [Color.white.opacity(0.98), Color.glassMint.opacity(0.66), Color.glassSky.opacity(0.56)],
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
                                Color.glassSky.opacity(0.42),
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
                    .fill(Color.white.opacity(0.72))
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

struct SlotHintVapor: View {
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

struct GoldenHintLetter: View {
    let letter: String
    let fontSize: CGFloat
    let strongGlow: Bool

    var body: some View {
        let glowGradient = LinearGradient(
            colors: [
                Color.white,
                Color.glassMint,
                Color.glassSky
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        Text(letter)
            .font(.system(size: fontSize, weight: .medium, design: .default))
            .foregroundStyle(glowGradient)
            .shadow(color: Color.glassMint.opacity(strongGlow ? 0.78 : 0.42), radius: strongGlow ? 28 : 10, x: 0, y: 0)
            .shadow(color: Color.glassSky.opacity(strongGlow ? 0.56 : 0.22), radius: strongGlow ? 54 : 16, x: 0, y: 0)
            .overlay(
                Text(letter)
                    .font(.system(size: fontSize, weight: .medium, design: .default))
                    .foregroundStyle(Color.white.opacity(strongGlow ? 0.35 : 0.12))
                    .blur(radius: strongGlow ? 1 : 0)
            )
    }
}

struct GoldenParticleBurst: View {
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
                        .fill(index.isMultiple(of: 2) ? Color.glassMint.opacity(0.96) : Color.glassSky.opacity(0.9))
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
                        .fill(index.isMultiple(of: 3) ? Color.glassSky.opacity(0.9) : Color.glassMint.opacity(0.76))
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
                        .fill(Color.glassPearl.opacity(0.2))
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
