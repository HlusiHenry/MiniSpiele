import SwiftUI

// MARK: - Shared HighScore Store
class GameData: ObservableObject {
    static let shared = GameData()

    @AppStorage("dice_high") var diceHigh = 0
    @AppStorage("reaction_best") var reactionBest: Double = 9999
    @AppStorage("word_wins") var wordWins = 0
    @AppStorage("word_games") var wordGames = 0
    @AppStorage("flick_score") var flickScore = 0
    @AppStorage("memory_best") var memoryBest = 9999
    @AppStorage("rps_wins") var rpsWins = 0
    @AppStorage("rps_games") var rpsGames = 0
}
