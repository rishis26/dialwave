import SwiftUI

/// A small colored dot used to indicate connection state in the menubar or UI.
struct StatusIndicatorView: View {
    let badge: ConnectionBadge
    
    @State private var pulse: Bool = false
    
    var body: some View {
        ZStack {
            if badge.shouldAnimate {
                Circle()
                    .fill(badge.color)
                    .scaleEffect(pulse ? 1.5 : 1.0)
                    .opacity(pulse ? 0 : 0.5)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                            pulse = true
                        }
                    }
                    .onChange(of: badge) { _, _ in
                        pulse = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                                pulse = true
                            }
                        }
                    }
            }
            
            Circle()
                .fill(badge.color)
                .frame(width: 8, height: 8)
        }
        .frame(width: 14, height: 14)
    }
}
