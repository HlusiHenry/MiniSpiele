import SwiftUI

// MARK: - Rock Paper Scissors vs AI
struct RPSGameView: View {
    @StateObject private var data = GameData.shared

    enum Choice: String, CaseIterable {
        case rock = "✊", paper = "✋", scissors = "✌️"
    }

    @State private var playerChoice: Choice?
    @State private var aiChoice: Choice?
    @State private var result: String?
    @State private var wins = 0
    @State private var losses = 0
    @State private var draws = 0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.25),
                                    Color(red: 0.05, green: 0.1, blue: 0.3)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(spacing: 24) {
                // Score
                HStack(spacing: 30) {
                    StatView(label: "Sieg", value: wins, color: .green)
                    StatView(label: "Niederlage", value: losses, color: .red)
                    StatView(label: "Unentschieden", value: draws, color: .yellow)
                }
                .padding(.horizontal)

                // AI area
                VStack(spacing: 8) {
                    Text("Computer").font(.subheadline).foregroundColor(.white.opacity(0.6))
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 120, height: 120)
                        if let choice = aiChoice {
                            Text(choice.rawValue)
                                .font(.system(size: 60))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("🤖")
                                .font(.system(size: 50))
                        }
                    }
                }

                // VS
                if let res = result {
                    Text(res)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(resultColor)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.vertical, 4)
                } else {
                    Text("Wähle:")
                        .font(.title2).foregroundColor(.white.opacity(0.7))
                }

                // Player area
                VStack(spacing: 8) {
                    Text("Du").font(.subheadline).foregroundColor(.white.opacity(0.6))
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 120, height: 120)
                        if let choice = playerChoice {
                            Text(choice.rawValue)
                                .font(.system(size: 60))
                        } else {
                            Text("❓")
                                .font(.system(size: 50))
                        }
                    }
                }

                // Choice buttons
                HStack(spacing: 20) {
                    ForEach(Choice.allCases, id: \.rawValue) { choice in
                        Button(action: { play(choice) }) {
                            Text(choice.rawValue)
                                .font(.system(size: 44))
                                .frame(width: 80, height: 80)
                                .background(
                                    Circle()
                                        .fill(LinearGradient(colors: [.indigo, .purple],
                                                             startPoint: .top, endPoint: .bottom))
                                        .shadow(color: .indigo.opacity(0.4), radius: 8, y: 4)
                                )
                        }
                        .disabled(isAnimating)
                    }
                }

                Button("Reset") { reset() }
                    .foregroundColor(.white.opacity(0.5)).padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: playerChoice as Choice?)
        .navigationTitle("Schere Stein Papier")
        .navigationBarTitleDisplayMode(.inline)
    }

    var resultColor: Color {
        guard let res = result else { return .white }
        if res.contains("Gewonnen") { return .green }
        if res.contains("Verloren") { return .red }
        return .yellow
    }

    func play(_ choice: Choice) {
        isAnimating = true
        playerChoice = choice
        aiChoice = nil
        result = nil

        // AI "thinking" animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let ai = Choice.allCases.randomElement()!
            aiChoice = ai

            if choice == ai {
                result = "Unentschieden"
                draws += 1
            } else if (choice == .rock && ai == .scissors) ||
                      (choice == .paper && ai == .rock) ||
                      (choice == .scissors && ai == .paper) {
                result = "Gewonnen! 🎉"
                wins += 1
                data.rpsWins += 1
            } else {
                result = "Verloren!"
                losses += 1
            }
            data.rpsGames += 1
            isAnimating = false
        }
    }

    func reset() {
        playerChoice = nil; aiChoice = nil; result = nil
        wins = 0; losses = 0; draws = 0
    }
}

struct StatView: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.bold().monospacedDigit())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
    }
}
