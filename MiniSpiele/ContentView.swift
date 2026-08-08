import SwiftUI

// MARK: - Game Card Model
struct GameInfo: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let description: String
    let gradient: [Color]
}

// MARK: - Main Menu
struct ContentView: View {
    let games: [GameInfo] = [
        GameInfo(id: "dice", title: "Würfelbecher", symbol: "dice.fill",
                 description: "Schütteln, würfeln, punkten", gradient: [.orange, .red]),
        GameInfo(id: "reaction", title: "Reaktion", symbol: "bolt.fill",
                 description: "Wie schnell bist du?", gradient: [.mint, .green]),
        GameInfo(id: "word", title: "WortRaten", symbol: "character.word.notext",
                 description: "5 Buchstaben, 6 Versuche", gradient: [.blue, .purple]),
        GameInfo(id: "flick", title: "TorSchießen", symbol: "soccerball",
                 description: "Flick den Ball ins Tor", gradient: [.green, .teal]),
        GameInfo(id: "memory", title: "Memory", symbol: "square.grid.2x2.fill",
                 description: "Finde alle Paare", gradient: [.pink, .orange]),
        GameInfo(id: "rps", title: "Schere Stein Papier", symbol: "hand.raised.fill",
                 description: "Schlag den Computer", gradient: [.indigo, .cyan]),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                                        Color(red: 0.1, green: 0.05, blue: 0.2)],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Text("MiniSpiele")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, Color(red: 0.7, green: 0.7, blue: 1.0)],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .padding(.top, 20)
                            .padding(.bottom, 4)

                        Text("gegen Langeweile")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.7))
                            .padding(.bottom, 30)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(games) { game in
                                NavigationLink(value: game.id) {
                                    GameCard(game: game)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationDestination(for: String.self) { id in
                switch id {
                case "dice": DiceGameView()
                case "reaction": ReactionGameView()
                case "word": WordGameView()
                case "flick": FlickGameView()
                case "memory": MemoryGameView()
                case "rps": RPSGameView()
                default: Text("Spiel nicht gefunden")
                }
            }
        }
    }
}

// MARK: - Game Card
struct GameCard: View {
    let game: GameInfo
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: game.symbol)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(height: 50)

            Text(game.title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(game.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: game.gradient,
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .shadow(color: game.gradient[0].opacity(0.4), radius: 10, y: 5)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
    }
}
