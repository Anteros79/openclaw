import OpenClawChatUI
import OpenClawKit
import OpenClawProtocol
import Foundation
import OSLog

struct VoiceConversationTransport: OpenClawChatTransport, Sendable {
    private static let logger = Logger(subsystem: "ai.openclaw", category: "ios.voice.transport")
    private let gateway: GatewayNodeSession

    init(gateway: GatewayNodeSession) {
        self.gateway = gateway
    }

    func abortRun(sessionKey: String, runId: String) async throws {
        struct Params: Codable {
            var sessionKey: String
            var runId: String
        }
        let data = try JSONEncoder().encode(Params(sessionKey: sessionKey, runId: runId))
        let json = String(data: data, encoding: .utf8)
        _ = try await self.gateway.request(method: "chat.abort", paramsJSON: json, timeoutSeconds: 10)
    }

    func listSessions(limit: Int?) async throws -> OpenClawChatSessionsListResponse {
        struct Params: Codable {
            var includeGlobal: Bool
            var includeUnknown: Bool
            var limit: Int?
        }
        let data = try JSONEncoder().encode(Params(includeGlobal: true, includeUnknown: false, limit: limit))
        let json = String(data: data, encoding: .utf8)
        let res = try await self.gateway.request(method: "sessions.list", paramsJSON: json, timeoutSeconds: 15)
        return try JSONDecoder().decode(OpenClawChatSessionsListResponse.self, from: res)
    }

    func setActiveSessionKey(_ sessionKey: String) async throws {
        // Voice conversations receive messages through voice events
    }

    func requestHistory(sessionKey: String) async throws -> OpenClawChatHistoryPayload {
        struct Params: Codable { var sessionKey: String }
        let data = try JSONEncoder().encode(Params(sessionKey: sessionKey))
        let json = String(data: data, encoding: .utf8)
        let res = try await self.gateway.request(method: "voice.history", paramsJSON: json, timeoutSeconds: 15)
        return try JSONDecoder().decode(OpenClawChatHistoryPayload.self, from: res)
    }

    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [OpenClawChatAttachmentPayload]) async throws -> OpenClawChatSendResponse
    {
        // Voice transport doesn't use text messages directly - it uses audio data
        // This method is implemented for protocol compliance but uses voice.send instead
        Self.logger.info("voice transport: sending text message (fallback) sessionKey=\(sessionKey, privacy: .public)")

        struct Params: Codable {
            var sessionKey: String
            var message: String
            var thinking: String
            var attachments: [OpenClawChatAttachmentPayload]?
            var timeoutMs: Int
            var idempotencyKey: String
        }

        let params = Params(
            sessionKey: sessionKey,
            message: message,
            thinking: thinking,
            attachments: attachments.isEmpty ? nil : attachments,
            timeoutMs: 30000,
            idempotencyKey: idempotencyKey)
        let data = try JSONEncoder().encode(params)
        let json = String(data: data, encoding: .utf8)

        do {
            let res = try await self.gateway.request(method: "chat.send", paramsJSON: json, timeoutSeconds: 35)
            let decoded = try JSONDecoder().decode(OpenClawChatSendResponse.self, from: res)
            Self.logger.info("voice transport: message sent runId=\(decoded.runId, privacy: .public)")
            return decoded
        } catch {
            Self.logger.error("voice transport: send failed \(error, privacy: .public)")
            throw error
        }
    }

    /// Send voice audio data to the gateway
    /// - Parameters:
    ///   - sessionKey: The session to send to
    ///   - audioData: Base64-encoded audio data
    ///   - audioFormat: Format of the audio (wav, mp3)
    ///   - duration: Duration of the audio in milliseconds
    ///   - idempotencyKey: Optional key for deduplication
    /// - Returns: Response with transcription and run ID
    func sendVoiceMessage(
        sessionKey: String,
        audioData: String,
        audioFormat: String = "wav",
        duration: Int,
        idempotencyKey: String) async throws -> OpenClawChatSendResponse
    {
        Self.logger.info("voice transport: sending audio sessionKey=\(sessionKey, privacy: .public) audioFormat=\(audioFormat) duration=\(duration)ms")

        struct Params: Codable {
            var sessionKey: String
            var audioData: String
            var audioFormat: String
            var duration: Int
            var idempotencyKey: String
        }

        let params = Params(
            sessionKey: sessionKey,
            audioData: audioData,
            audioFormat: audioFormat,
            duration: duration,
            idempotencyKey: idempotencyKey)
        let data = try JSONEncoder().encode(params)
        let json = String(data: data, encoding: .utf8)

        do {
            let res = try await self.gateway.request(method: "voice.send", paramsJSON: json, timeoutSeconds: 35)
            let decoded = try JSONDecoder().decode(OpenClawChatSendResponse.self, from: res)
            Self.logger.info("voice transport: audio sent runId=\(decoded.runId, privacy: .public)")
            return decoded
        } catch {
            Self.logger.error("voice transport: send failed \(error, privacy: .public)")
            throw error
        }
    }
}
