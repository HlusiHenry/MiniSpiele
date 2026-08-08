import SwiftUI
import CoreHaptics

// MARK: - Dice Game (Yahtzee-Style)
struct DiceGameView: View {
    @StateObject private var data = GameData.shared
    @State private var dice: [Int] = [1, 3, 5, 2, 6]
    @State private var held: Set<Int> = []
    @State private var rollsLeft = 3
    @State private var scores: [String: Int] = [:]
    @State private var selectedCategory: String?
    @State private var engine: CHHapticEngine?

    let categories = ["Einser", "Zweier", "Dreier", "Vierer", "Fünfer", "Sechser",
                      "Dreierpasch", "Viererpasch", "Full House",
                      "Kleine Straße", "Große Straße", "Kniffel", "Chance"]

    var totalScore: Int {
        scores.values.compactMap { $0 }.reduce(0, +)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.15, green: 0.05, blue: 0.05),
                                    Color(red: 0.25, green: 0.1, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(spacing: 16) {
                // Score header
                Text("\(totalScore) Punkte")
                    .font(.system(.title, design: .rounded)).bold().foregroundColor(.white)
                Text(rollsLeft > 0 ? "\(rollsLeft) Würfe übrig" : "Kategorie wählen!")
                    .font(.subheadline).foregroundColor(.orange)

                // Dice row
                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { i in
                        DieView(value: dice[i], isHeld: held.contains(i))
                            .onTapGesture {
                                if held.contains(i) { held.remove(i) }
                                else { held.insert(i) }
                            }
                    }
                }
                .padding(.vertical, 12)

                // Roll button
                if rollsLeft > 0 {
                    Button(action: rollDice) {
                        Label("Würfeln", systemImage: "hand.draw.fill")
                            .font(.title3.bold())
                            .padding(.horizontal, 40).padding(.vertical, 14)
                            .background(Capsule().fill(LinearGradient(colors: [.orange, .red],
                                                                      startPoint: .top, endPoint: .bottom)))
                            .foregroundColor(.white)
                    }
                }

                // Scorecard
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(categories, id: \.self) { cat in
                            ScoreCell(category: cat, value: scores[cat],
                                      isSelectable: rollsLeft == 0,
                                      suggestedScore: rollsLeft == 0 ? calculateScore(cat) : nil)
                                .onTapGesture {
                                    guard rollsLeft == 0, scores[cat] == nil else { return }
                                    scores[cat] = calculateScore(cat)
                                    if let score = scores[cat], score > data.diceHigh { data.diceHigh = score }
                                    resetTurn()
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                }

                // New game
                Button("Neues Spiel") { resetGame() }
                    .foregroundColor(.orange).padding(.bottom, 10)
            }
        }
        .navigationTitle("Würfelbecher")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prepareHaptics(); resetGame() }
        .onShake { if rollsLeft > 0 { rollDice() } }
    }

    func rollDice() {
        guard rollsLeft > 0 else { return }
        for i in 0..<5 where !held.contains(i) {
            dice[i] = Int.random(in: 1...6)
        }
        rollsLeft -= 1
        triggerHaptic()
    }

    func calculateScore(_ cat: String) -> Int {
        let counts = Dictionary(grouping: dice, by: { $0 }).mapValues { $0.count }
        let sum = dice.reduce(0, +)
        let sorted = dice.sorted()

        switch cat {
        case "Einser": return dice.filter { $0 == 1 }.count * 1
        case "Zweier": return dice.filter { $0 == 2 }.count * 2
        case "Dreier": return dice.filter { $0 == 3 }.count * 3
        case "Vierer": return dice.filter { $0 == 4 }.count * 4
        case "Fünfer": return dice.filter { $0 == 5 }.count * 5
        case "Sechser": return dice.filter { $0 == 6 }.count * 6
        case "Dreierpasch": return counts.values.contains(where: { $0 >= 3 }) ? sum : 0
        case "Viererpasch": return counts.values.contains(where: { $0 >= 4 }) ? sum : 0
        case "Full House": return (counts.values.contains(3) && counts.values.contains(2)) ? 25 : 0
        case "Kleine Straße":
            let sets: Set<Int> = [[1,2,3,4],[2,3,4,5],[3,4,5,6]].first { Set(sorted).isSuperset(of: $0) } != nil ? [1,2,3,4] : []
            return sets.isEmpty ? 0 : 30
        case "Große Straße": return Set(sorted) == [1,2,3,4,5] || Set(sorted) == [2,3,4,5,6] ? 40 : 0
        case "Kniffel": return counts.values.contains(5) ? 50 : 0
        case "Chance": return sum
        default: return 0
        }
    }

    func resetTurn() { dice = [1,1,1,1,1]; held = []; rollsLeft = 3 }
    func resetGame() { scores = [:]; dice = [1,3,5,2,6]; held = []; rollsLeft = 3 }

    func prepareHaptics() { engine = try? CHHapticEngine(); try? engine?.start() }
    func triggerHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let events = (0..<3).map { i -> CHHapticEvent in
            let p = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            return CHHapticEvent(eventType: .hapticTransient, parameters: [p, s], relativeTime: Double(i) * 0.08)
        }
        try? engine?.makePlayer(with: try CHHapticPattern(events: events, parameterCurves: [])).start(atTime: 0)
    }
}

struct DieView: View {
    let value: Int
    let isHeld: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isHeld ? Color.orange : Color.white.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHeld ? Color.orange : Color.white.opacity(0.3), lineWidth: 2))
                .frame(width: 60, height: 60)

            // Dots
            DotPattern(value: value)
                .foregroundColor(.white)
        }
        .scaleEffect(isHeld ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHeld)
    }
}

struct DotPattern: View {
    let value: Int

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            let p = s * 0.22
            let c = s / 2

            ForEach(dotPositions, id: \.x) { pos in
                Circle().frame(width: p, height: p)
                    .position(x: pos.x * c + c, y: pos.y * c + c)
            }
        }
    }

    var dotPositions: [(x: CGFloat, y: CGFloat)] {
        switch value {
        case 1: return [(0,0)]
        case 2: return [(-0.5,-0.5),(0.5,0.5)]
        case 3: return [(-0.5,-0.5),(0,0),(0.5,0.5)]
        case 4: return [(-0.5,-0.5),(0.5,-0.5),(-0.5,0.5),(0.5,0.5)]
        case 5: return [(-0.5,-0.5),(0.5,-0.5),(0,0),(-0.5,0.5),(0.5,0.5)]
        case 6: return [(-0.5,-0.5),(0.5,-0.5),(-0.5,0),(0.5,0),(-0.5,0.5),(0.5,0.5)]
        default: return []
        }
    }
}

struct ScoreCell: View {
    let category: String
    let value: Int?
    let isSelectable: Bool
    let suggestedScore: Int?

    var body: some View {
        HStack {
            Text(category).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
            Spacer()
            if let score = value {
                Text("\(score)").font(.caption.bold()).foregroundColor(.green)
            } else if let s = suggestedScore, isSelectable {
                Text("\(s)").font(.caption).foregroundColor(.orange.opacity(0.7))
            } else if isSelectable {
                Text("-").font(.caption).foregroundColor(.white.opacity(0.3))
            } else {
                Text("").font(.caption)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
    }
}

// Shake gesture
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShake")
}
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
struct ShakeModifier: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            action()
        }
    }
}
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeModifier(action: action))
    }
}
