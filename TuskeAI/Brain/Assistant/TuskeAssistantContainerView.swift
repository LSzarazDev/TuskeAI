import SwiftUI

struct TuskeAssistantContainerView: View {
    @Binding var showLegacyUI: Bool
    @Binding var assistantState: TuskeAssistantState
    @State private var isExpanded = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                fullAssistantView
            } else {
                collapsedBubble
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fullAssistantView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Spacer()

                    Button {
                        showLegacyUI = true
                    } label: {
                        Text("Legacy chat")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Text("Tüske")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text(assistantState.title)
                    .font(.caption)
                    .foregroundColor(.cyan)
                    .padding(.bottom, 4)

                TuskeAvatarVisual(state: assistantState)
                    .frame(width: 330, height: 420)

                HStack(spacing: 12) {
                    ForEach(TuskeAssistantState.allCases, id: \.self) { item in
                        Button {
                            assistantState = item
                        } label: {
                            Text(item.title)
                                .font(.caption2)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(assistantState == item ? Color.cyan.opacity(0.22) : Color.white.opacity(0.05))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var collapsedBubble: some View {
        TuskeAssistantBubbleView(
            size: 84,
            accentColor: .cyan,
            action: {
                isExpanded = true
                assistantState = .idle
            }
        )
        .padding(.trailing, 18)
        .padding(.bottom, 18)
    }
}
