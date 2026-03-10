import OpenClawChatUI
import OpenClawKit
import SwiftUI

struct VoiceConversationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OpenClawChatViewModel
    @State private var isRecording = false
    @State private var recordingTimer = 0.0
    @State private var micLevel: Double = 0
    @Environment(VoiceWakeManager.self) private var voiceWake
    @Environment(TalkModeManager.self) private var talkMode

    private let userAccent = Color(red: 0, green: 0.4, blue: 1) // Blue accent for voice
    private let sessionKey: String

    init(gateway: GatewayNodeSession, sessionKey: String) {
        let transport = VoiceConversationTransport(gateway: gateway)
        self._viewModel = State(
            initialValue: OpenClawChatViewModel(
                sessionKey: sessionKey,
                transport: transport))
        self.sessionKey = sessionKey
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background (Jarvis Core style)
                Color(red: 0.04, green: 0.06, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Voice Conversation")
                                .font(.headline)
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(Color(red: 0.06, green: 0.08, blue: 0.18))
                    .borderBottom(width: 1, color: Color(red: 0, green: 0.4, blue: 1, opacity: 0.2))

                    // Main content area
                    HStack(spacing: 16) {
                        // Activity log (center/left)
                        VoiceActivityLogView(viewModel: viewModel)

                        // Agent activity monitor (right)
                        AgentActivityPanel()
                    }
                    .padding()

                    Spacer()

                    // Voice input controls
                    VoiceControlsView(
                        isRecording: $isRecording,
                        recordingTimer: $recordingTimer,
                        micLevel: $micLevel,
                        sessionKey: sessionKey,
                        viewModel: viewModel)
                    .padding()
                    .background(Color(red: 0.06, green: 0.08, blue: 0.18))
                    .borderTop(width: 1, color: Color(red: 0, green: 0.4, blue: 1, opacity: 0.2))
                }
            }
            .navigationTitle("Voice Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

// Voice controls with hold-to-talk button
struct VoiceControlsView: View {
    @Binding var isRecording: Bool
    @Binding var recordingTimer: Double
    @Binding var micLevel: Double
    let sessionKey: String
    let viewModel: OpenClawChatViewModel
    @Environment(TalkModeManager.self) private var talkMode

    private let buttonSize: CGFloat = 80

    var body: some View {
        VStack(spacing: 20) {
            // Waveform visualization
            if isRecording {
                VoiceWaveformView(level: micLevel)
                    .frame(height: 40)
            }

            // Recording timer
            if isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text(formatTime(recordingTimer))
                        .font(.caption)
                        .monospaced()
                    Spacer()
                }
            }

            // Hold-to-talk button
            VStack {
                Text(isRecording ? "RECORDING" : "Hold to talk")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ZStack {
                    // Button background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0, green: 0.4, blue: 1),
                                    Color(red: 0, green: 0.8, blue: 1),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: Color(red: 0, green: 0.4, blue: 1, opacity: 0.5),
                                radius: isRecording ? 15 : 8)
                        .scaleEffect(isRecording ? 1.1 : 1.0)

                    // Microphone icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isRecording {
                                startRecording()
                            }
                        }
                        .onEnded { _ in
                            if isRecording {
                                stopRecording()
                            }
                        }
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func startRecording() {
        isRecording = true
        recordingTimer = 0
        micLevel = 0

        // Start timer
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTimer += 0.1
            // Update mic level from TalkModeManager
            micLevel = talkMode.micLevel
        }

        // Store timer reference for cleanup (in real app, use proper state management)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            timer.invalidate()
        }
    }

    private func stopRecording() {
        isRecording = false
        recordingTimer = 0

        // In real implementation, this would:
        // 1. Get audio data from recorder
        // 2. Encode to base64
        // 3. Call viewModel.sendVoiceMessage with audio data
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// Animated waveform visualization
struct VoiceWaveformView: View {
    let level: Double
    @State private var displayBars: [Double] = Array(repeating: 0, count: 20)

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<displayBars.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0, green: 0.8, blue: 1))
                    .frame(height: CGFloat(displayBars[index]) * 40)
            }
        }
        .onChange(of: level) { _, newLevel in
            withAnimation(.easeInOut(duration: 0.1)) {
                for i in 0..<displayBars.count {
                    displayBars[i] = Double.random(in: newLevel * 0.5...newLevel)
                }
            }
        }
    }
}

// Activity log view showing voice transcript and agent actions
struct VoiceActivityLogView: View {
    let viewModel: OpenClawChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("TRANSCRIPT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0, green: 0.4, blue: 1))
                    Spacer()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            VoiceTranscriptEntry(message: message)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding()
            .background(Color(red: 0.06, green: 0.08, blue: 0.18))
            .cornerRadius(8)
            .border(Color(red: 0, green: 0.4, blue: 1, opacity: 0.2), width: 1)
        }
    }
}

// Single transcript entry
struct VoiceTranscriptEntry: View {
    let message: OpenClawChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                let prefix = message.role == "user" ? "[VOICE]" : "[RESPONSE]"
                let color: Color = message.role == "user" ? Color(red: 0, green: 0.4, blue: 1) : Color(red: 0, green: 0.8, blue: 1)

                Text(prefix)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(ISO8601DateFormatter().string(from: Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(message.text ?? "")
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(nil)
        }
    }
}

#Preview {
    VoiceConversationSheet(gateway: GatewayNodeSession(gatewayUrl: "ws://localhost:8000"), sessionKey: "test")
}

// Helper extension for borders
extension View {
    func borderBottom(width: CGFloat, color: Color) -> some View {
        self.overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(color)
                    .frame(height: width)
            }
        )
    }

    func borderTop(width: CGFloat, color: Color) -> some View {
        self.overlay(
            VStack {
                Rectangle()
                    .fill(color)
                    .frame(height: width)
                Spacer()
            }
        )
    }
}
