import { Type } from "@sinclair/typebox";
import { NonEmptyString } from "./primitives.js";

export const VoiceSendParamsSchema = Type.Object(
  {
    sessionKey: NonEmptyString,
    audioData: Type.String(), // Base64-encoded audio data
    audioFormat: Type.Optional(Type.Enum({ wav: "wav", mp3: "mp3" })), // Default: wav
    duration: Type.Optional(Type.Number()), // Duration in milliseconds
    idempotencyKey: Type.Optional(NonEmptyString), // For deduplication
  },
  { additionalProperties: false },
);

export const VoiceSendResultSchema = Type.Object(
  {
    runId: Type.String(),
    sessionKey: Type.String(),
    transcription: Type.String(),
    state: Type.Enum({ pending: "pending", streaming: "streaming", final: "final" }),
  },
  { additionalProperties: false },
);

export const VoiceHistoryParamsSchema = Type.Object(
  {
    sessionKey: NonEmptyString,
    limit: Type.Optional(Type.Number()),
  },
  { additionalProperties: false },
);

export const AgentStatusParamsSchema = Type.Object(
  {
    sessionKey: Type.Optional(NonEmptyString), // Optional: filter by requester session
  },
  { additionalProperties: false },
);

export const AgentStatusResultSchema = Type.Object(
  {
    activeAgents: Type.Array(
      Type.Object(
        {
          runId: Type.String(),
          childSessionKey: Type.String(),
          requesterSessionKey: Type.String(),
          parentRunId: Type.Optional(Type.String()), // If this is a subagent, parent's runId
          taskDescription: Type.Optional(Type.String()),
          startedAt: Type.Number(),
          elapsedMs: Type.Number(),
          state: Type.Enum({ active: "active", idle: "idle", streaming: "streaming" }),
        },
        { additionalProperties: false },
      ),
    ),
    activeConnections: Type.Number(), // Count of active network connections
    timestamp: Type.Number(),
  },
  { additionalProperties: false },
);

export type VoiceSendParams = typeof VoiceSendParamsSchema.static;
export type VoiceSendResult = typeof VoiceSendResultSchema.static;
export type VoiceHistoryParams = typeof VoiceHistoryParamsSchema.static;
export type AgentStatusParams = typeof AgentStatusParamsSchema.static;
export type AgentStatusResult = typeof AgentStatusResultSchema.static;
