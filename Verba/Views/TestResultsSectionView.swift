import SwiftUI

struct TestResultsView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var vm: TestViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            let percentage = Double(vm.score) / Double(max(1, vm.queue.count))

            VStack(spacing: 10) {
                Image(systemName: percentage >= 0.7 ? "trophy.fill" : "checkmark.seal.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(percentage >= 0.7 ? DesignSystem.Feedback.successGradient : DesignSystem.Feedback.failureGradient)

                Text(lm.t("test_results"))
                    .font(.system(size: 30, weight: .medium, design: .default))
                    .foregroundColor(.white)

                Text("\(vm.score) / \(vm.queue.count)")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.72))
            }
            .padding(16)
            .glassPanel(cornerRadius: 20, edgeHighlight: Color.glassSky.opacity(0.2))

            Text("\(Int(percentage * 100))%")
                .font(.system(size: 70, weight: .medium, design: .default))
                .foregroundStyle(percentage >= 0.7 ? DesignSystem.Feedback.successGradient : DesignSystem.Feedback.failureGradient)

            if !vm.wrongAnswers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(lm.t("review_wrong"))
                        .font(.headline)
                        .foregroundColor(.glassTeal)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(0..<vm.wrongAnswers.count, id: \.self) { index in
                                HStack(spacing: 10) {
                                    Text(vm.wrongAnswers[index].0)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(vm.wrongAnswers[index].1)
                                        .foregroundColor(.red)
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

            Button(lm.t("finish"), action: onFinish)
                .buttonStyle(GlassButtonStyle())
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
