import SwiftUI
import SwiftData

// MARK: - View

struct TestView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var vm: TestViewModel
    
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage("animationSpeed") var animationSpeed: Double = 1.0
    
    init(set: WordSet) {
        self.set = set
        _vm = State(initialValue: TestViewModel(set: set))
    }
    
    var body: some View {
        VStack {
            if vm.isSetup {
                setupView
            } else if vm.isFinished {
                resultsView
            } else {
                questionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(vm.feedbackColor.opacity(0.3).ignoresSafeArea())
        .background(Color.deepNavy.ignoresSafeArea())
        .onAppear {
            vm.setup(modelContext: ctx, dismiss: { dismiss() })
        }
    }
    
    // MARK: - Subviews
    
    private var setupView: some View {
        VStack(spacing: 30) {
            Text(lm.t("test_setup"))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Text("\(lm.t("questions")): \(Int(vm.questionCount))")
                        .font(.headline)
                        .foregroundColor(.glassCyan)
                    
                    Slider(value: $vm.questionCount, in: 5...50, step: 5)
                        .tint(.glassCyan)
                        .frame(maxWidth: 400)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Image(systemName: vm.isMultipleChoice ? "list.bullet" : "pencil")
                        .font(.title3)
                        .foregroundColor(.glassCyan)
                        .frame(width: 30)
                    
                    Toggle(lm.t("multiple_choice"), isOn: $vm.isMultipleChoice)
                        .toggleStyle(SwitchToggleStyle(tint: .glassCyan))
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .padding(30)
            .glassEffect()
            .frame(maxWidth: 500)
            
            Button(action: { 
                withAnimation(.spring()) { vm.startTest() }
            }) {
                Text(lm.t("start"))
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.glassCyan.opacity(0.8))
                    .cornerRadius(14)
                    .glassEffect()
            }
            .buttonStyle(PlainButtonStyle())
            .pressAnimation()
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            Text(lm.t("test_results")).font(.largeTitle).foregroundColor(.white)
            
            let percentage = Double(vm.score) / Double(max(1, vm.queue.count))
            Text("\(Int(percentage * 100))%")
                .font(.system(size: 100, weight: .black))
                .foregroundColor(percentage >= 0.7 ? .green : (percentage >= 0.5 ? .orange : .red))
            
            Text("\(vm.score) / \(vm.queue.count)").font(.title).foregroundColor(.white.opacity(0.8))
            
            if !vm.wrongAnswers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(lm.t("review_wrong")).font(.headline).foregroundColor(.glassCyan).padding(.bottom, 5)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(0..<vm.wrongAnswers.count, id: \.self) { i in
                                HStack {
                                    Text(vm.wrongAnswers[i].0).foregroundColor(.white)
                                    Spacer()
                                    Text(vm.wrongAnswers[i].1).foregroundColor(.glassCyan).bold()
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }.frame(maxHeight: 250)
                }
                .padding().glassEffect().frame(maxWidth: 600)
            }
            
            Button(lm.t("finish")) { vm.finishTestAndSave() }.buttonStyle(GlassButtonStyle()).padding()
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 5) {
            Text("\(vm.currentIdx + 1) / \(vm.queue.count)")
                .font(.caption).bold().foregroundColor(.white.opacity(0.5))
            
            ProgressView(value: Double(vm.currentIdx), total: Double(vm.queue.count))
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.glassCyan)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                .frame(height: 4)
                .animation(.easeInOut(duration: 0.3), value: vm.currentIdx)
                .padding(.horizontal)
            
            Spacer()
            
            if let _ = vm.current {
                Text(vm.prompt)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 700)
                    .padding(.vertical, 40)
                    .glassEffect()
                    .padding()
                
                if vm.isMultipleChoice {
                    VStack(spacing: 15) {
                        ForEach(vm.mcOptions, id: \.self) { opt in
                            Button(action: { vm.submitMC(opt) }) {
                                Text(opt)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: 500)
                                    .background(buttonBackground(for: opt))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(vm.selectedOption == opt ? 1.05 : 1.0)
                            .animation(animationSpeed > 0 ? .spring() : nil, value: vm.selectedOption)
                            .disabled(vm.selectedOption != nil)
                        }
                    }.padding()
                } else {
                    TextField("...", text: $vm.answer)
                        .textFieldStyle(.plain).padding().glassEffect().font(.title)
                        .frame(maxWidth: 600)
                        .padding(.horizontal, 40)
                        .onSubmit { vm.submitOpen() }
                        .disabled(vm.selectedOption != nil)
                    
                    if vm.showCorrectAnswer {
                        Text(vm.target)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.glassCyan)
                            .padding(.top, 8)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: vm.showCorrectAnswer)
                    }
                }
            }
            Spacer()
        }
        .padding(.top)
    }
    
    private func buttonBackground(for opt: String) -> some View {
        Group {
            if let selected = vm.selectedOption {
                if opt == vm.target {
                    Color.green.opacity(0.6)
                } else if opt == selected {
                    Color.red.opacity(0.6)
                } else {
                    Color.white.opacity(0.1)
                }
            } else {
                Color.white.opacity(0.1)
            }
        }
    }
}
