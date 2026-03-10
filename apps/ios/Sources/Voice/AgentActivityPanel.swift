import SwiftUI
import Foundation
import OSLog

@MainActor
@Observable
final class AgentActivityManager {
    private static let logger = Logger(subsystem: "ai.openclaw", category: "ios.agent-activity")
    var activeAgents: [AgentStatusEntry] = []
    var activeConnections: Int = 0
    var lastUpdated: Date = Date()
    private var updateTask: Task<Void, Never>?

    struct AgentStatusEntry: Identifiable {
        let id: String // runId
        let childSessionKey: String
        let taskDescription: String?
        let startedAt: Date
        let elapsedMs: Int
        let state: String
        let parentRunId: String?

        var elapsedTimeFormatted: String {
            let seconds = elapsedMs / 1000
            let minutes = seconds / 60
            if minutes > 0 {
                return "\(minutes)m \(seconds % 60)s"
            }
            return "\(seconds)s"
        }

        var isChild: Bool {
            parentRunId != nil
        }
    }

    func startMonitoring(gateway: GatewayNodeSession?, sessionKey: String?) {
        stopMonitoring()

        updateTask = Task {
            while !Task.isCancelled {
                if let gateway = gateway, let sessionKey = sessionKey {
                    await updateAgentStatus(gateway: gateway, sessionKey: sessionKey)
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
        }
    }

    func stopMonitoring() {
        updateTask?.cancel()
        updateTask = nil
    }

    private func updateAgentStatus(gateway: GatewayNodeSession, sessionKey: String) async {
        do {
            struct Params: Codable {
                var sessionKey: String?
            }

            let params = Params(sessionKey: sessionKey)
            let encoder = JSONEncoder()
            let data = try encoder.encode(params)
            let json = String(data: data, encoding: .utf8)

            let response = try await gateway.request(
                method: "agent.status",
                paramsJSON: json,
                timeoutSeconds: 5)

            let decoder = JSONDecoder()
            let result = try decoder.decode(AgentStatusResponse.self, from: response)

            await MainActor.run {
                self.activeAgents = result.activeAgents.map { agent in
                    AgentStatusEntry(
                        id: agent.runId,
                        childSessionKey: agent.childSessionKey,
                        taskDescription: agent.taskDescription,
                        startedAt: Date(timeIntervalSince1970: TimeInterval(agent.startedAt / 1000)),
                        elapsedMs: agent.elapsedMs,
                        state: agent.state,
                        parentRunId: agent.parentRunId)
                }
                self.activeConnections = result.activeConnections
                self.lastUpdated = Date()
            }
        } catch {
            Self.logger.error("Failed to fetch agent status: \(error, privacy: .public)")
        }
    }

    struct AgentStatusResponse: Codable {
        struct Agent: Codable {
            let runId: String
            let childSessionKey: String
            let requesterSessionKey: String
            let parentRunId: String?
            let taskDescription: String?
            let startedAt: Int
            let elapsedMs: Int
            let state: String
        }

        let activeAgents: [Agent]
        let activeConnections: Int
        let timestamp: Int
    }
}

// Agent Activity Panel View
struct AgentActivityPanel: View {
    @State private var agentActivityManager = AgentActivityManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("AGENT ACTIVITY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                Spacer()
                HStack(spacing: 4) {
                    Text("\(agentActivityManager.activeAgents.count) active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Active agents list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if agentActivityManager.activeAgents.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("All agents idle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                    } else {
                        ForEach(agentActivityManager.activeAgents) { agent in
                            AgentStatusRow(agent: agent)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(Color(red: 0, green: 0.4, blue: 1, opacity: 0.2))

            // Network activity
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("↓↑")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1, green: 0.6, blue: 0))
                    Text("\(agentActivityManager.activeConnections) connections")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(formatTimeAgo(agentActivityManager.lastUpdated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(red: 0.06, green: 0.08, blue: 0.18))
        .cornerRadius(8)
        .border(Color(red: 0, green: 0.8, blue: 1, opacity: 0.2), width: 1)
        .frame(maxWidth: 280)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                agentActivityManager.startMonitoring(gateway: nil, sessionKey: nil)
            } else {
                agentActivityManager.stopMonitoring()
            }
        }
    }
}

// Individual agent status row
struct AgentStatusRow: View {
    let agent: AgentActivityManager.AgentStatusEntry

    var statusColor: Color {
        switch agent.state {
        case "active", "streaming":
            return Color(red: 0, green: 0.8, blue: 1)
        case "idle":
            return Color.green
        default:
            return .secondary
        }
    }

    var statusIcon: String {
        switch agent.state {
        case "streaming":
            return "waveform.circle.fill"
        case "active":
            return "play.circle.fill"
        case "idle":
            return "checkmark.circle.fill"
        default:
            return "circle.dashed"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    if agent.isChild {
                        HStack(spacing: 4) {
                            Text("└─")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Subagent")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("Router")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    if let taskDescription = agent.taskDescription {
                        Text(taskDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(agent.elapsedTimeFormatted)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)

                    Text(agent.state.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(red: 0.08, green: 0.1, blue: 0.22))
        .cornerRadius(6)
    }
}

private func formatTimeAgo(_ date: Date) -> String {
    let elapsed = Date().timeIntervalSince(date)
    if elapsed < 60 {
        return "just now"
    } else if elapsed < 3600 {
        let mins = Int(elapsed / 60)
        return "\(mins)m ago"
    } else {
        let hours = Int(elapsed / 3600)
        return "\(hours)h ago"
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.06, blue: 0.15)
        AgentActivityPanel()
            .padding()
    }
}
