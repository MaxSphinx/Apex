import SwiftUI

public struct BiometricShieldHUDView: View {
    @ObservedObject private var prefs = ApexPreferences.shared
    @ObservedObject private var faceEngine = BiometricFaceEngine.shared
    @State private var newAppBundleId = ""
    @State private var testAlertStatus = ""
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // FaceLock Master Toggle
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "faceid")
                            .font(.system(size: 20))
                            .foregroundColor(.apexCyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Neural Engine FaceLock")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Locks protected windows when unauthorized faces are detected.")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $prefs.faceLockEnabled)
                            .toggleStyle(.switch)
                    }
                    
                    // Live Status Pill
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(faceEngine.isFacePresent ? Color.apexEmerald : Color.apexCoral)
                                .frame(width: 8, height: 8)
                            Text(faceEngine.isFacePresent ? "User Face Verified via Apple Neural Engine" : "Camera Ready (Awaiting Protected App)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                                .foregroundColor(.apexCyan)
                            Text("Enrolled 128-D Templates: \(faceEngine.enrolledVectorsCount) vectors (\(faceEngine.enrolledVectorsCount > 0 ? "Strict ANFRv4 Match" : "Presence Detection"))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
                .padding(14)
                .glassCard(borderColor: prefs.faceLockEnabled ? Color.apexCyan.opacity(0.3) : Color.apexBorder)
                
                // Protected Apps List
                VStack(alignment: .leading, spacing: 10) {
                    Text("PROTECTED APPLICATIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 6) {
                        ForEach(prefs.protectedApps, id: \.self) { appBundle in
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.apexPurple)
                                Text(appBundle)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { removeProtectedApp(appBundle) }) {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(6)
                        }
                    }
                    
                    // Add app input
                    HStack {
                        TextField("e.g. com.tinyspeck.slackmacgap", text: $newAppBundleId)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Button(action: addProtectedApp) {
                            Text("Add")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.apexCyan.opacity(0.2))
                                .foregroundColor(.apexCyan)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(newAppBundleId.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                }
                .padding(14)
                .glassCard()
                
                // Telegram Security Alerts Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.apexCyan)
                        Text("TELEGRAM INTRUDER ALERTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        Toggle("", isOn: $prefs.telegramAlertsEnabled)
                            .toggleStyle(.switch)
                    }
                    
                    if prefs.telegramAlertsEnabled {
                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bot API Token")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                SecureField("123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ", text: $prefs.telegramBotToken)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(6)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Chat ID")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                TextField("e.g. 987654321", text: $prefs.telegramChatId)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(6)
                            }
                            
                            HStack {
                                if !testAlertStatus.isEmpty {
                                    Text(testAlertStatus)
                                        .font(.system(size: 10))
                                        .foregroundColor(.apexEmerald)
                                }
                                Spacer()
                                Button(action: sendTestAlert) {
                                    Text("Send Test Alert")
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.apexCyan.opacity(0.2))
                                        .foregroundColor(.apexCyan)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
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
    
    private func addProtectedApp() {
        let clean = newAppBundleId.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, !prefs.protectedApps.contains(clean) else { return }
        prefs.protectedApps.append(clean)
        newAppBundleId = ""
    }
    
    private func removeProtectedApp(_ bundleId: String) {
        prefs.protectedApps.removeAll(where: { $0 == bundleId })
    }
    
    private func sendTestAlert() {
        testAlertStatus = "Sending..."
        TelegramAlertEngine.shared.sendIntruderAlert(appName: "Test Target") { success in
            testAlertStatus = success ? "✓ Alert Delivered" : "✗ Delivery Failed"
        }
    }
}
