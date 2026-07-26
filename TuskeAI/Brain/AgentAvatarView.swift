import SwiftUI

struct AgentAvatarView: View {
    let agent: Agent
    let size: CGFloat

    var body: some View {
        Image(agent.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(
                RoundedRectangle(cornerRadius: size * 0.22)
            )
    }
}
