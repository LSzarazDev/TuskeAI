import SwiftUI

struct TuskeAvatarVisual: View {
    let state: TuskeAssistantState
    @State private var pulse = false
    @State private var shimmer = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.1), Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 300, height: 300)
                    .blur(radius: 35)
                    .opacity(state == .sick || state == .error ? 0.2 : 0.8)

                ParticleField(state: state)
                    .frame(width: 340, height: 420)
                    .scaleEffect(pulse ? 1.05 : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }

                VStack(spacing: 0) {
                    Circle()
                        .fill(Color(white: 0.12))
                        .frame(width: 130, height: 150)
                        .overlay(
                            Circle()
                                .stroke(Color.cyan.opacity(0.6), lineWidth: 1.4)
                        )
                        .offset(y: -8)

                    Capsule()
                        .fill(Color(white: 0.09))
                        .frame(width: 140, height: 160)
                        .overlay(
                            Capsule()
                                .stroke(Color.cyan.opacity(0.45), lineWidth: 1.2)
                        )
                        .offset(y: 10)
                }
                .scaleEffect(state == .speaking ? 1.02 : 1)

                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.black.opacity(0.9))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(0.85))
                                    .frame(width: 8, height: 8)
                            )
                        Circle()
                            .fill(Color.black.opacity(0.9))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(0.85))
                                    .frame(width: 8, height: 8)
                            )
                    }
                    .offset(y: -12)

                    Capsule()
                        .fill(Color.cyan.opacity(state == .speaking ? 0.7 : 0.4))
                        .frame(width: 52, height: 10)
                        .offset(y: 18)
                        .scaleEffect(state == .speaking ? 1.2 : 1)
                        .animation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true), value: state)
                }
                .offset(y: -30)

                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.06), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 220, height: 120)
                        .offset(y: 60)
                        .opacity(0.8)
                }
            }
            .frame(width: 340, height: 420)
            .rotation3DEffect(.degrees(6), axis: (x: 0, y: 1, z: 0))
            .shadow(color: .cyan.opacity(0.25), radius: 24, x: 0, y: 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

private struct ParticleField: View {
    let state: TuskeAssistantState

    var body: some View {
        ZStack {
            ForEach(0..<80, id: \ .self) { index in
                let x = CGFloat(index % 10) * 30 + 18
                let y = CGFloat(index / 10) * 26 + 14
                let scale = 2.0 + Double(index % 5) * 0.4
                let color: Color = {
                    switch state {
                    case .angry: return .red
                    case .sick, .error: return .gray
                    case .thinking: return .white
                    default: return .cyan
                    }
                }()

                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: CGFloat(scale), height: CGFloat(scale))
                    .position(x: x, y: y)
                    .offset(x: index.isMultiple(of: 2) ? 34 : -10, y: index.isMultiple(of: 3) ? 30 : 0)
                    .animation(.linear(duration: 2.5).repeatForever(autoreverses: true), value: state)
            }
        }
        .blur(radius: state == .sick || state == .error ? 0.8 : 0.2)
    }
}
