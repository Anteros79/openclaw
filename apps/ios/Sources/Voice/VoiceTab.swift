import SwiftUI

struct VoiceTab: View {
    @Environment(NodeAppModel.self) private var appModel
    @Environment(VoiceWakeManager.self) private var voiceWake
    @AppStorage(“voiceWake.enabled”) private var voiceWakeEnabled: Bool = false
    @AppStorage(“talk.enabled”) private var talkEnabled: Bool = false
    @State private var showVoiceConversation: Bool = false
    @State private var conversationSessionKey: String = “voice-main”

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background (Jarvis Core style)
                Color(red: 0.04, green: 0.06, blue: 0.15)
                    .ignoresSafeArea()

                List {
                    Section(“Voice Conversation”) {
                        Button(action: { showVoiceConversation = true }) {
                            HStack {
                                Image(systemName: “mic.circle.fill”)
                                    .font(.title2)
                                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                                VStack(alignment: .leading) {
                                    Text(“Start Voice Chat”)
                                        .fontWeight(.semibold)
                                    Text(“Hold to talk with AI”)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: “chevron.right”)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Section(“Voice Wake Settings”) {
                        LabeledContent(“Voice Wake”, value: self.voiceWakeEnabled ? “Enabled” : “Disabled”)
                        LabeledContent(“Listener”, value: self.voiceWake.isListening ? “Listening” : “Idle”)
                        Text(self.voiceWake.statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        LabeledContent(“Talk Mode”, value: self.talkEnabled ? “Enabled” : “Disabled”)
                    }

                    Section(“Wake Words”) {
                        let triggers = self.voiceWake.activeTriggerWords
                        Group {
                            if triggers.isEmpty {
                                Text(“Add wake words in Settings.”)
                            } else if triggers.count == 1 {
                                Text(“Say “\(triggers[0]) …” to trigger.”)
                            } else if triggers.count == 2 {
                                Text(“Say “\(triggers[0]) …” or “\(triggers[1]) …” to trigger.”)
                            } else {
                                Text(“Say “\(triggers.joined(separator: “ …”, “”)) …” to trigger.”)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(“Voice”)
                .onChange(of: self.voiceWakeEnabled) { _, newValue in
                    self.appModel.setVoiceWakeEnabled(newValue)
                }
                .onChange(of: self.talkEnabled) { _, newValue in
                    self.appModel.setTalkEnabled(newValue)
                }
            }
            .sheet(isPresented: $showVoiceConversation) {
                if let gateway = appModel.gateway {
                    VoiceConversationSheet(gateway: gateway, sessionKey: conversationSessionKey)
                }
            }
        }
    }
}
