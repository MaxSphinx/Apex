import SwiftUI

public struct VolumeMixerHUDView: View {
    @ObservedObject private var audio = AudioEngine.shared
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Master Audio Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "hifispeaker.fill")
                            .foregroundColor(.apexCyan)
                        Text("MASTER OUTPUT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        
                        // Output device picker
                        Menu {
                            ForEach(audio.outputDevices) { device in
                                Button(action: { audio.selectOutputDevice(device) }) {
                                    HStack {
                                        Text(device.name)
                                        if device.name == audio.defaultOutputDeviceName {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(audio.defaultOutputDeviceName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { audio.isMuted.toggle() }) {
                            Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                .font(.system(size: 16))
                                .foregroundColor(audio.isMuted ? .apexCoral : .apexCyan)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Slider(value: $audio.masterVolume, in: 0...1)
                            .accentColor(.apexCyan)
                        
                        Text("\(Int(audio.masterVolume * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                .padding(14)
                .glassCard(borderColor: Color.apexCyan.opacity(0.3))
                
                // Per-Application Mixer Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("PER-APPLICATION VOLUME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: { audio.refresh() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if audio.appTargets.isEmpty {
                        HStack {
                            Spacer()
                            Text("No active media applications detected")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(audio.appTargets) { target in
                                HStack(spacing: 10) {
                                    if let icon = target.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: "app.fill")
                                            .frame(width: 24, height: 24)
                                    }
                                    
                                    Text(target.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 100, alignment: .leading)
                                        .lineLimit(1)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { target.volume },
                                            set: { audio.setAppVolume(bundleIdentifier: target.bundleIdentifier, volume: $0) }
                                        ),
                                        in: 0...1
                                    )
                                    .accentColor(.apexPurple)
                                    
                                    Button(action: { audio.toggleAppMute(bundleIdentifier: target.bundleIdentifier) }) {
                                        Image(systemName: target.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(target.isMuted ? .apexCoral : .gray)
                                            .frame(width: 24, height: 24)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(14)
                .glassCard()
            }
            .padding(16)
        }
    }
}
