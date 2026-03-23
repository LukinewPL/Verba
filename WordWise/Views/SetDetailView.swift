import SwiftUI

struct SetDetailView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @Environment(\.modelContext) var ctx
    @State private var navigateStudy = false
    @State private var navigateSpeedRound = false
    @State private var navigateTest = false
    
    var body: some View {
        VStack {
            HStack {
                Button(lm.t("study")) {
                    navigateStudy = true
                }
                .buttonStyle(GlassButtonStyle())

                Button(lm.t("speed_round")) {
                    navigateSpeedRound = true
                }
                .buttonStyle(GlassButtonStyle())

                Button(lm.t("test")) {
                    navigateTest = true
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding()

            Picker(
                lm.t("translation"),
                selection: $set.translationDirectionRaw
            ) {
                Text("PL → EN").tag(0)
                Text("EN → PL").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List(set.words) { w in
                HStack {
                    Text(w.polish)
                    Spacer()
                    Text(w.english)
                    if w.isMastered {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(set.name)
        .background(Color.deepNavy.ignoresSafeArea())
        .navigationDestination(isPresented: $navigateStudy) {
            StudySessionView(set: set)
        }
        .navigationDestination(isPresented: $navigateSpeedRound) {
            SpeedRoundView(set: set)
        }
        .navigationDestination(isPresented: $navigateTest) {
            TestView(set: set)
        }
    }
}
