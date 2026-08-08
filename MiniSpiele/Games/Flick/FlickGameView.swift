import SwiftUI

// MARK: - Flick Soccer Game
struct FlickGameView: View {
    @StateObject private var data = GameData.shared

    @State private var ballPos = CGPoint(x: 0, y: 250)
    @State private var goaliePos: CGFloat = 0
    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var velocity: CGVector = .zero
    @State private var score = 0
    @State private var attempts = 0
    @State private var goalieMoving = false
    @State private var showResult = false
    @State private var lastResult = ""
    @State private var timer: Timer?

    let goalY: CGFloat = -180
    let goalWidth: CGFloat = 140
    let goalHeight: CGFloat = 60

    var body: some View {
        ZStack {
            // Field
            LinearGradient(colors: [Color(red: 0.1, green: 0.35, blue: 0.1),
                                    Color(red: 0.05, green: 0.2, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            GeometryReader { geo in
                let midX = geo.size.width / 2
                let midY = geo.size.height / 2

                ZStack {
                    // Field lines
                    Rectangle().fill(Color.white.opacity(0.3)).frame(width: geo.size.width - 40, height: 2)
                        .position(x: midX, y: midY - 100)

                    Rectangle().fill(Color.white.opacity(0.2)).frame(width: 100, height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.white.opacity(0.4), lineWidth: 2))
                        .position(x: midX, y: midY + goalY + 30)

                    // Goal post
                    Path { p in
                        p.move(to: CGPoint(x: midX - goalWidth/2, y: midY + goalY + goalHeight))
                        p.addLine(to: CGPoint(x: midX - goalWidth/2, y: midY + goalY - 10))
                        p.addLine(to: CGPoint(x: midX + goalWidth/2, y: midY + goalY - 10))
                        p.addLine(to: CGPoint(x: midX + goalWidth/2, y: midY + goalY + goalHeight))
                    }
                    .stroke(Color.white, lineWidth: 4)

                    // Net pattern
                    ForEach(0..<4) { i in
                        Path { p in
                            p.move(to: CGPoint(x: midX - goalWidth/2 + goalWidth * CGFloat(i) / 4, y: midY + goalY - 10))
                            p.addLine(to: CGPoint(x: midX - goalWidth/2 + goalWidth * CGFloat(i) / 4, y: midY + goalY + goalHeight))
                        }
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }

                    // Goalie
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        .overlay(Text("🧤").font(.system(size: 16)))
                        .position(x: midX + goaliePos * goalWidth/2, y: midY + goalY + 10)

                    // Ball (with drag)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1)
                                .overlay(HexagonPattern().stroke(Color.black.opacity(0.3), lineWidth: 0.5))
                        )
                        .position(x: midX + ballPos.x, y: midY + ballPos.y)
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        dragStart = ballPos
                                    }
                                    ballPos = CGPoint(x: dragStart.x + value.translation.width,
                                                      y: dragStart.y + value.translation.height)
                                }
                                .onEnded { value in
                                    isDragging = false
                                    velocity = CGVector(dx: -value.predictedEndTranslation.width / 15,
                                                        dy: -value.predictedEndTranslation.height / 15)
                                    launchBall()
                                }
                        )
                }
                .onAppear { startGoalie(geo: geo) }
            }

            // Score HUD
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tore: \(score)").font(.headline.bold()).foregroundColor(.white)
                        Text("Schüsse: \(attempts)").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4)))
                    Spacer()
                }
                .padding(.horizontal)
                Spacer()
            }

            // Result popup
            if showResult {
                VStack {
                    Text(lastResult)
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(lastResult == "TOOOR!" ? .yellow : .red)
                        .transition(.scale.combined(with: .opacity))
                    Button("Weiter") {
                        withAnimation { showResult = false; resetBall() }
                    }
                    .font(.headline).padding(.horizontal, 30).padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.2))).foregroundColor(.white)
                }
            }
        }
        .navigationTitle("TorSchießen")
        .navigationBarTitleDisplayMode(.inline)
    }

    func startGoalie(geo: GeometryProxy) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                goaliePos = CGFloat.random(in: -0.85...0.85)
            }
        }
    }

    func launchBall() {
        attempts += 1
        var pos = ballPos
        var vel = velocity

        // Simple physics simulation
        for _ in 0..<60 {
            pos.x += vel.dx
            pos.y += vel.dy
            vel.dy += 1.5 // gravity
            vel.dx *= 0.98 // friction

            // Check goal
            if pos.y <= goalY + goalHeight && pos.y >= goalY - 10 &&
                abs(pos.x) < goalWidth/2 {
                // Check goalie
                if abs(pos.x - goaliePos * goalWidth/2) > 18 {
                    score += 1
                    if score > data.flickScore { data.flickScore = score }
                    lastResult = "TOOOR!"
                    showResult = true
                    return
                } else {
                    lastResult = "Gehalten!"
                    showResult = true
                    return
                }
            }

            // Out of bounds (y too low = went back)
            if pos.y > 350 || pos.y < -300 {
                lastResult = "Daneben!"
                showResult = true
                return
            }
        }
        lastResult = "Daneben!"
        showResult = true
    }

    func resetBall() {
        ballPos = CGPoint(x: 0, y: 250)
        velocity = .zero
    }
}

struct HexagonPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let s = rect.width * 0.3
        for r in 0..<3 {
            let angle = Double(r) * .pi * 2 / 3
            let x = rect.midX + cos(angle) * s
            let y = rect.midY + sin(angle) * s
            if r == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}
