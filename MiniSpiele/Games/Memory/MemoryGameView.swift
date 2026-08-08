import SwiftUI

// MARK: - Memory Card Game
struct MemoryGameView: View {
    @StateObject private var data = GameData.shared

    let emojis = ["🍎","🍋","🍇","🍒","🍊","🍓","🥑","🌽"]
    let gridSize = 4

    @State private var cards: [MemoryCard] = []
    @State private var flippedIndices: Set<Int> = []
    @State private var matchedIndices: Set<Int> = []
    @State private var moves = 0
    @State private var isChecking = false
    @State private var gameComplete = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.2, green: 0.05, blue: 0.1),
                                    Color(red: 0.15, green: 0.02, blue: 0.08)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Züge: \(moves)")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Text("Paare: \(matchedIndices.count/2)/\(emojis.count)")
                        .font(.headline).foregroundColor(.white)
                }
                .padding(.horizontal, 24)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize), spacing: 8) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                        MemoryCardView(card: card, isFlipped: flippedIndices.contains(i) || matchedIndices.contains(i))
                            .onTapGesture { flipCard(at: i) }
                            .opacity(matchedIndices.contains(i) ? 0.4 : 1.0)
                    }
                }
                .padding(.horizontal, 16)

                if gameComplete {
                    VStack(spacing: 8) {
                        Text("🎉 Geschafft!").font(.title.bold()).foregroundColor(.yellow)
                        Text("\(moves) Züge").foregroundColor(.white)
                        Button("Neues Spiel") { resetGame() }
                            .font(.headline).padding(.horizontal, 30).padding(.vertical, 10)
                            .background(Capsule().fill(Color.pink)).foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resetGame() }
    }

    func flipCard(at index: Int) {
        guard !isChecking else { return }
        guard !matchedIndices.contains(index) else { return }
        guard !flippedIndices.contains(index) else { return }
        guard flippedIndices.count < 2 else { return }

        flippedIndices.insert(index)

        if flippedIndices.count == 2 {
            moves += 1
            isChecking = true
            let pair = Array(flippedIndices)
            if cards[pair[0]].emoji == cards[pair[1]].emoji {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    matchedIndices.formUnion(pair)
                    flippedIndices.removeAll()
                    isChecking = false
                    if matchedIndices.count == cards.count {
                        gameComplete = true
                        if moves < data.memoryBest { data.memoryBest = moves }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    flippedIndices.removeAll()
                    isChecking = false
                }
            }
        }
    }

    func resetGame() {
        var deck = emojis + emojis
        deck.shuffle()
        cards = deck.map { MemoryCard(emoji: $0) }
        flippedIndices = []
        matchedIndices = []
        moves = 0
        isChecking = false
        gameComplete = false
    }
}

struct MemoryCard: Identifiable {
    let id = UUID()
    let emoji: String
}

struct MemoryCardView: View {
    let card: MemoryCard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isFlipped ? AnyShapeStyle(Color.white.opacity(0.12)) :
                        AnyShapeStyle(LinearGradient(colors: [.pink, .purple],
                                       startPoint: .top, endPoint: .bottom)))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .pink.opacity(0.3), radius: 5, y: 3)

            if isFlipped {
                Text(card.emoji)
                    .font(.system(size: 32))
            } else {
                Text("?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: 0.3), value: isFlipped)
    }
}
