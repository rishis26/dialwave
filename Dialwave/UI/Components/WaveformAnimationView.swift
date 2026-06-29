import SwiftUI

/// A pulsating waveform animation used for active calls and Bluetooth scanning.
struct WaveformAnimationView: View {
    
    // MARK: - Properties
    
    let color: Color
    let isAnimating: Bool
    
    @State private var phase1: CGFloat = 0.0
    @State private var phase2: CGFloat = 0.0
    @State private var phase3: CGFloat = 0.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 2)
                .scaleEffect(isAnimating ? (1.0 + phase1 * 0.5) : 1.0)
                .opacity(isAnimating ? (1.0 - phase1) : 0)
                
            Circle()
                .stroke(color, lineWidth: 2)
                .scaleEffect(isAnimating ? (1.0 + phase2 * 0.5) : 1.0)
                .opacity(isAnimating ? (1.0 - phase2) : 0)
                
            Circle()
                .stroke(color, lineWidth: 2)
                .scaleEffect(isAnimating ? (1.0 + phase3 * 0.5) : 1.0)
                .opacity(isAnimating ? (1.0 - phase3) : 0)
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            phase1 = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard isAnimating else { return }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                phase2 = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard isAnimating else { return }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                phase3 = 1.0
            }
        }
    }
    
    private func stopAnimation() {
        withAnimation {
            phase1 = 0
            phase2 = 0
            phase3 = 0
        }
    }
}
