import SwiftUI

struct TuskeAssistantBubbleView: View {
    let size: CGFloat
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [accentColor, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: size, height: size)
                    .shadow(color: accentColor.opacity(0.45), radius: 18, x: 0, y: 10)

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}
