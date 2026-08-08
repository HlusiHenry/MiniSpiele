import SwiftUI

// MARK: - Reaction Game
struct ReactionGameView: View {
    @StateObject private var data = GameData.shared

    enum Phase { case waiting, ready, red, green, result }
    @State private var gamePhase: Phase = .waiting
    @State private var startTime: Date = .now
    @State private var reactionTime: Double = 0
    @State private var lastTimes: [Double] = []

    var bestTime: Double { data.reactionBest < 9998 ? data.reactionBest : 0 }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea().animation(.easeInOut(duration: 0.3), value: gamePhase)

            VStack(spacing: 24) {
                switch gamePhase {
                case .waiting:
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.fill").font(.system(size: 60)).foregroundColor(.yellow)
                        Text("Reaktions-Test").font(.largeTitle.bold()).foregroundColor(.white)
                        Text("Tippe auf den Bildschirm wenn er grün wird.\nNicht zu früh!").multilineTextAlignment(.center).foregroundColor(.white.opacity(0.7))
                        Button("Start") { withAnimation { gamePhase = .ready } }
                            .font(.title2.bold()).padding(.horizontal, 50).padding(.vertical, 16)
                            .background(Capsule().fill(Color.green)).foregroundColor(.white)
                    }

                case .ready:
                    Text("Bereit?")
                        .font(.system(size: 48, weight: .bold)).foregroundColor(.white)

                case .red:
                    VStack(spacing: 16) {
                        Text("Warte...").font(.title).foregroundColor(.white.opacity(0.6))
                        Text("⚫️").font(.system(size: 80))
                    }

                case .green:
                    VStack(spacing: 16) {
                        Text("JETZT!").font(.system(size: 56, weight: .black)).foregroundColor(.white)
                        Text("🟢").font(.system(size: 80))
                    }

                case .result:
                    VStack(spacing: 16) {
                        Text(reactionTime < 1000 ? "\(String(format: "%.0f", reactionTime)) ms" : "Zu früh!")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(reactionTime < 1000 ? .yellow : .red)

                        Text(reactionLabel)
                            .font(.title3).foregroundColor(.white.opacity(0.8))

                        if bestTime > 0 {
                            Text("Bestzeit: \(String(format: "%.0f", bestTime)) ms")
                                .font(.subheadline).foregroundColor(.green)
                        }

                        // Last 5 results
                        if !lastTimes.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(lastTimes.suffix(5).reversed(), id: \.self) { t in
                                    Text(String(format: "%.0f", t))
                                        .font(.caption2.monospacedDigit())
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Capsule().fill(Color.white.opacity(0.15)))
                                        .foregroundColor(.white)
                                }
                            }
                        }

                        Button("Nochmal") { startRound() }
                            .font(.title3.bold()).padding(.horizontal, 40).padding(.vertical, 12)
                            .background(Capsule().fill(Color.blue)).foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .navigationTitle("Reaktion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startRound() }
        }
    }

    var backgroundColor: Color {
        switch gamePhase {
        case .red: return Color.red.opacity(0.8)
        case .green: return Color.green.opacity(0.9)
        case .result: return Color(red: 0.1, green: 0.05, blue: 0.2)
        default: return Color(red: 0.08, green: 0.08, blue: 0.18)
        }
    }

    var reactionLabel: String {
        switch reactionTime {
        case ..<150: return "🔥 Übermenschlich!"
        case ..<200: return "⚡️ Blitzschnell!"
        case ..<250: return "👏 Richtig gut!"
        case ..<300: return "👍 Solide"
        case ..<400: return "😐 Geht so"
        case ..<1000: return "🐌 Langsam"
        default: return "💀 Zu früh!"
        }
    }

    func startRound() {
        gamePhase = .red
        let delay = Double.random(in: 1.5...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if gamePhase == .red {
                gamePhase = .green
                startTime = Date()
            }
        }
    }

    func handleTap() {
        switch gamePhase {
        case .waiting: return
        case .ready: startRound()
        case .red:
            reactionTime = 9999
            gamePhase = .result
        case .green:
            reactionTime = Date().timeIntervalSince(startTime) * 1000
            lastTimes.append(reactionTime)
            if lastTimes.count > 20 { lastTimes.removeFirst() }
            if reactionTime < data.reactionBest { data.reactionBest = reactionTime }
            gamePhase = .result
        case .result: startRound()
        }
    }
}
