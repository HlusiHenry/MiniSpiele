import SwiftUI

// MARK: - German Wordle Clone
struct WordGameView: View {
    @StateObject private var data = GameData.shared

    let wordLength = 5
    let maxGuesses = 6
    let words: [String] = ["APFEL", "BIRNE", "BLUME", "BRAUN", "DACHS", "EICHE", "FARBE",
                            "GABEL", "HAFEN", "HALLO", "HECHT", "HUNDE", "INSEL", "JACKE",
                            "KATZE", "KERZE", "KISTE", "KLEIN", "KNOCH", "LAMPE", "LEISE",
                            "LICHT", "LINDE", "LIPPE", "MASKE", "MAUER", "MILCH", "MONAT",
                            "MUSIK", "NADEL", "NARBE", "ORDEN", "PERLE", "PFERD", "PFLAU",
                            "PLATZ", "RATTE", "REGEN", "RINDE", "ROSA", "SAHNE", "SALAT",
                            "SCHAF", "SEIFE", "SILBE", "SPIEL", "STADT", "STEIN", "STERN",
                            "STUHL", "TASSE", "TAUBE", "TISCH", "TORTE", "TRAUM", "UHREN",
                            "WALZE", "WELLE", "WELPE", "WIESE", "WOLKE", "WURST", "ZEBRA"]

    @State private var targetWord = ""
    @State private var guesses: [String] = []
    @State private var currentGuess = ""
    @State private var shakeRow = false
    @State private var gameOver = false
    @State private var won = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.2),
                                    Color(red: 0.1, green: 0.05, blue: 0.25)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(spacing: 10) {
                Text("WortRaten")
                    .font(.title.bold()).foregroundColor(.white).padding(.top, 8)

                // Word grid
                VStack(spacing: 6) {
                    ForEach(0..<maxGuesses, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<wordLength, id: \.self) { col in
                                let letter = letterAt(row: row, col: col)
                                let state = letterState(row: row, col: col)
                                LetterBox(letter: letter, state: state)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .modifier(ShakeEffect(shakes: shakeRow ? 2 : 0))
                .animation(.default, value: shakeRow)

                // Keyboard
                VStack(spacing: 4) {
                    ForEach(keyboardRows, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(row, id: \.self) { key in
                                KeyboardKey(key: key, state: keyState(key),
                                            action: { keyTapped(key) })
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)

                if gameOver {
                    VStack(spacing: 8) {
                        Text(won ? "🎉 Richtig!" : "😔 \(targetWord)")
                            .font(.title2.bold()).foregroundColor(won ? .green : .red)
                        Button("Neues Wort") { newGame() }
                            .font(.headline).padding(.horizontal, 30).padding(.vertical, 10)
                            .background(Capsule().fill(Color.purple)).foregroundColor(.white)
                    }
                    .padding(.top, 8)
                }

                Text("Gewonnen: \(data.wordWins)/\(data.wordGames)")
                    .font(.caption).foregroundColor(.white.opacity(0.5))
            }
        }
        .navigationTitle("WortRaten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newGame() }
    }

    var keyboardRows: [[String]] {
        [["Q","W","E","R","T","Z","U","I","O","P"],
         ["A","S","D","F","G","H","J","K","L"],
         ["⌫","Y","X","C","V","B","N","M","⏎"]]
    }

    func letterAt(row: Int, col: Int) -> Character {
        guard row < guesses.count else { return " " }
        let guess = guesses[row]
        guard col < guess.count else { return " " }
        return guess[guess.index(guess.startIndex, offsetBy: col)]
    }

    func letterState(row: Int, col: Int) -> LetterState {
        guard row < guesses.count else { return .empty }
        let guess = guesses[row]
        guard col < guess.count else { return .empty }

        let idx = guess.index(guess.startIndex, offsetBy: col)
        let letter = guess[idx]

        if targetWord[idx] == letter { return .correct }

        // Count occurrences
        var targetCounts: [Character: Int] = [:]
        for (i, c) in targetWord.enumerated() {
            if guess[guess.index(guess.startIndex, offsetBy: i)] != c {
                targetCounts[c, default: 0] += 1
            }
        }

        var used = 0
        for i in 0..<col {
            let gi = guess.index(guess.startIndex, offsetBy: i)
            if guess[gi] == letter && targetWord[gi] != letter {
                used += 1
            }
        }

        if targetWord.contains(letter) && used < (targetCounts[letter] ?? 0) {
            return .wrongPosition
        }
        return .absent
    }

    func keyState(_ key: String) -> LetterState {
        if key == "⌫" || key == "⏎" { return .empty }
        guard let char = key.first else { return .empty }
        var state: LetterState = .empty

        for guess in guesses {
            for (i, c) in guess.enumerated() {
                guard c == char else { continue }
                let idx = targetWord.index(targetWord.startIndex, offsetBy: i)
                if targetWord[idx] == c { return .correct }
                if targetWord.contains(c) { state = .wrongPosition }
                else if state == .empty { state = .absent }
            }
        }
        return state
    }

    func keyTapped(_ key: String) {
        guard !gameOver else { return }

        switch key {
        case "⌫":
            if !currentGuess.isEmpty { currentGuess.removeLast() }
        case "⏎":
            submitGuess()
        default:
            if currentGuess.count < wordLength {
                currentGuess.append(key)
            }
        }
    }

    func submitGuess() {
        guard currentGuess.count == wordLength else { return }
        guard words.contains(currentGuess) else {
            shakeRow = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shakeRow = false }
            return
        }

        guesses.append(currentGuess)

        if currentGuess == targetWord {
            won = true; gameOver = true
            data.wordWins += 1; data.wordGames += 1
        } else if guesses.count >= maxGuesses {
            gameOver = true; data.wordGames += 1
        }

        currentGuess = ""
    }

    func newGame() {
        targetWord = words.randomElement() ?? "HALLO"
        guesses = []; currentGuess = ""; gameOver = false; won = false
    }
}

// MARK: - Sub-views
enum LetterState { case empty, correct, wrongPosition, absent }

struct LetterBox: View {
    let letter: Character
    let state: LetterState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .frame(width: 52, height: 52)
            if letter != " " {
                Text(String(letter))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    var backgroundColor: Color {
        switch state {
        case .empty: return .white.opacity(0.1)
        case .correct: return .green
        case .wrongPosition: return .orange
        case .absent: return Color(red: 0.3, green: 0.3, blue: 0.3)
        }
    }
}

struct KeyboardKey: View {
    let key: String
    let state: LetterState
    let action: () -> Void
    let isSpecial: Bool

    init(key: String, state: LetterState, action: @escaping () -> Void) {
        self.key = key; self.state = state; self.action = action
        self.isSpecial = key == "⌫" || key == "⏎"
    }

    var body: some View {
        Button(action: action) {
            Text(key)
                .font(.system(size: isSpecial ? 18 : 16, weight: .semibold))
                .frame(width: isSpecial ? 44 : 32, height: 44)
                .background(bgColor)
                .foregroundColor(.white)
                .cornerRadius(5)
        }
    }

    var bgColor: Color {
        switch state {
        case .correct: return .green
        case .wrongPosition: return .orange
        case .absent: return Color(red: 0.3, green: 0.3, blue: 0.3)
        case .empty: return Color(red: 0.45, green: 0.45, blue: 0.5)
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: CGFloat(shakes % 2 == 0 ? -6 : 6), y: 0))
    }
}
