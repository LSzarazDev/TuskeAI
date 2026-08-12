import SwiftUI

struct TuskeAssistantRootView: View {
    @State private var assistantState: TuskeAssistantState = .idle
    @State private var showLegacyUI = false
    @State private var isBubbleExpanded = true
    @State private var inputText = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showLegacyUI {
                legacyFallbackView
            } else if isBubbleExpanded {
                fullAssistantView
            } else {
                bubbleView
            }
        }
        .preferredColorScheme(.dark)
    }

    private var fullAssistantView: some View {
        VStack(spacing: 0) {
            headerBar

            Spacer(minLength: 10)

            TuskeAvatarVisual(state: assistantState)
                .frame(width: 330, height: 420)
                .padding(.bottom, 12)

            statusPill
                .padding(.bottom, 12)

            assistantControls
                .padding(.bottom, 12)

            chatPanel
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            inputBar
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TüskeAI")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text("mobil asszisztens")
                    .font(.caption)
                    .foregroundColor(.cyan.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    showLegacyUI = true
                } label: {
                    Text("Legacy")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    isBubbleExpanded = false
                } label: {
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colorForState(assistantState))
                .frame(width: 10, height: 10)

            Text(assistantState.title)
                .font(.caption)
                .bold()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var assistantControls: some View {
        HStack(spacing: 10) {
            ForEach(TuskeAssistantState.allCases, id: \.self) { state in
                Button {
                    assistantState = state
                } label: {
                    Text(state.title)
                        .font(.caption2)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 56)
                        .background(state == assistantState ? Color.cyan.opacity(0.22) : Color.white.opacity(0.06))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chatPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aktuális állapot")
                .font(.headline)
                .foregroundColor(.white)

            ContentView(assistantState: $assistantState)
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Color.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button {
                assistantState = .listening
            } label: {
                Image(systemName: "mic.fill")
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.cyan.opacity(0.18))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            TextField("Írd be, amit szeretnél...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.white)
                .tint(.cyan)

            Button {
                assistantState = .speaking
            } label: {
                Text("Küldés")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var bubbleView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                TuskeAssistantBubbleView(
                    size: 86,
                    accentColor: .cyan,
                    action: {
                        isBubbleExpanded = true
                        assistantState = .idle
                    }
                )
                .padding(.trailing, 18)
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }

    private var legacyFallbackView: some View {
        ZStack(alignment: .topTrailing) {
            ContentView(assistantState: $assistantState)
                .ignoresSafeArea()

            Button {
                showLegacyUI = false
                isBubbleExpanded = true
            } label: {
                Text("Tüske UI")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }

    private func colorForState(_ state: TuskeAssistantState) -> Color {
        switch state {
        case .idle: return .cyan
        case .listening: return .cyan
        case .thinking: return .blue
        case .speaking: return .mint
        case .angry: return .red
        case .sick: return .gray
        case .error: return .red
        }
    }
}
