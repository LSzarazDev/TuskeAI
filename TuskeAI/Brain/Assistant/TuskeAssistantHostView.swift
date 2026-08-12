import SwiftUI

struct TuskeAssistantHostView: View {
    @State private var isExpanded = true
    @State private var state: TuskeAssistantState = .idle

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                assistantFullView
            } else {
                assistantBubble
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var assistantFullView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Tüske")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text(state.title)
                    .font(.caption)
                    .foregroundColor(.cyan)
                    .padding(.bottom, 4)

                TuskeAvatarVisual(state: state)
                    .frame(width: 330, height: 420)

                HStack(spacing: 12) {
                    ForEach(TuskeAssistantState.allCases, id: \.self) { item in
                        Button {
                            state = item
                        } label: {
                            Text(item.rawValue.capitalized)
                                .font(.caption2)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(state == item ? Color.cyan.opacity(0.22) : Color.white.opacity(0.05))
                                .foregroundColor(.white)
                                .cornerRadius(999)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

    private var assistantBubble: some View {
        Button {
            isExpanded = true
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                    .shadow(color: .cyan.opacity(0.45), radius: 18, x: 0, y: 8)

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 18)
        .padding(.bottom, 18)
    }
}
