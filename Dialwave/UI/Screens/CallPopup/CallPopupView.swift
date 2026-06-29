import SwiftUI

/// The floating HUD presented when an incoming call arrives or is active.
struct CallPopupView: View {
    
    @StateObject var viewModel: CallPopupViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Header: Avatar and Name
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dialwavePrimary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    if viewModel.state.isAnswered {
                        WaveformAnimationView(color: .dialwavePrimary, isAnimating: true)
                            .frame(width: 120, height: 120)
                    }
                    
                    Text(viewModel.displayName.initials)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.dialwavePrimary)
                }
                
                VStack(spacing: 4) {
                    Text(viewModel.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if viewModel.state.isAnswered {
                        Text(viewModel.formattedDuration)
                            .font(.subheadline)
                            .foregroundColor(.dialwavePrimary)
                    } else {
                        Text("Incoming Call…")
                            .font(.subheadline)
                            .foregroundColor(.dialwaveSecondary)
                    }
                }
            }
            .padding(.top, 24)
            
            Spacer()
            
            // Controls
            HStack(spacing: 20) {
                if viewModel.state.isAnswered {
                    // Hangup only
                    Button(action: viewModel.hangup) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.dialwaveRed)
                            .clipShape(Circle())
                            .shadow(color: .dialwaveRed.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                } else {
                    // Decline / Answer
                    Button(action: viewModel.decline) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.dialwaveRed)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: viewModel.answer) {
                        Image(systemName: "phone.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.dialwaveGreen)
                            .clipShape(Circle())
                            .shadow(color: .dialwaveGreen.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: 300, height: 420)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        // Invisible border to catch shadows
        .padding(20)
    }
}

// MARK: - Visual Effect

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
