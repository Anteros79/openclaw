import { listSubagentRunsForRequester } from "../../agents/subagent-registry.js";
import { stripEnvelopeFromMessages } from "../chat-sanitize.js";
import { ErrorCodes, errorShape, formatValidationErrors } from "../protocol/index.js";
import {
  VoiceSendParamsSchema,
  VoiceHistoryParamsSchema,
  AgentStatusParamsSchema,
  type VoiceSendParams,
  type VoiceHistoryParams,
  type AgentStatusParams,
  type AgentStatusResult,
} from "../protocol/schema/voice.js";
import { loadSessionEntry, readSessionMessages } from "../session-utils.js";
import type { GatewayRequestHandlers } from "./types.js";

const Ajv = require("ajv").default;
const ajv = new Ajv();

const validateVoiceSendParams = ajv.compile(VoiceSendParamsSchema);
const validateVoiceHistoryParams = ajv.compile(VoiceHistoryParamsSchema);
const validateAgentStatusParams = ajv.compile(AgentStatusParamsSchema);

export const voiceHandlers: GatewayRequestHandlers = {
  "voice.send": async ({ params, respond }) => {
    if (!validateVoiceSendParams(params)) {
      respond(
        false,
        undefined,
        errorShape(
          ErrorCodes.INVALID_REQUEST,
          `invalid voice.send params: ${formatValidationErrors(validateVoiceSendParams.errors)}`,
        ),
      );
      return;
    }

    const { sessionKey } = params as VoiceSendParams;

    try {
      // Load session
      const { entry } = loadSessionEntry(sessionKey);
      if (!entry) {
        respond(false, undefined, errorShape(ErrorCodes.INVALID_REQUEST, "session not found"));
        return;
      }

      // TODO: In a real implementation, transcribe audio here
      // For now, return a placeholder transcription
      const transcription = "[Audio transcription would go here]";

      // Create a response indicating the message was received
      const response = {
        runId: `voice-${Date.now()}`,
        sessionKey,
        transcription,
        state: "pending" as const,
      };

      respond(true, response);
    } catch (error) {
      respond(
        false,
        undefined,
        errorShape(
          ErrorCodes.INTERNAL_ERROR,
          `voice.send failed: ${error instanceof Error ? error.message : "unknown error"}`,
        ),
      );
    }
  },

  "voice.history": async ({ params, respond }) => {
    if (!validateVoiceHistoryParams(params)) {
      respond(
        false,
        undefined,
        errorShape(
          ErrorCodes.INVALID_REQUEST,
          `invalid voice.history params: ${formatValidationErrors(validateVoiceHistoryParams.errors)}`,
        ),
      );
      return;
    }

    const { sessionKey, limit } = params as VoiceHistoryParams;

    try {
      const { cfg, entry, storePath } = loadSessionEntry(sessionKey);
      if (!entry || !storePath) {
        respond(false, undefined, errorShape(ErrorCodes.INVALID_REQUEST, "session not found"));
        return;
      }

      // Load message history
      const messages = readSessionMessages(storePath, entry, cfg);
      const sanitized = stripEnvelopeFromMessages(messages);

      // Filter to voice-related messages and apply limit
      const voiceMessages = sanitized.filter(
        (msg) => msg.role === "user" || msg.role === "assistant",
      );
      const limitedMessages = limit ? voiceMessages.slice(-limit) : voiceMessages;

      respond(true, { messages: limitedMessages }, undefined);
    } catch (error) {
      respond(
        false,
        undefined,
        errorShape(
          ErrorCodes.INTERNAL_ERROR,
          `voice.history failed: ${error instanceof Error ? error.message : "unknown error"}`,
        ),
      );
    }
  },

  "agent.status": async ({ params, respond, context }) => {
    if (!validateAgentStatusParams(params)) {
      respond(
        false,
        undefined,
        errorShape(
          ErrorCodes.INVALID_REQUEST,
          `invalid agent.status params: ${formatValidationErrors(validateAgentStatusParams.errors)}`,
        ),
      );
      return;
    }

    const { sessionKey } = params as AgentStatusParams;

    try {
      // Get active subagent runs
      const requesterSessionKey = sessionKey || "global";
      const activeRuns = listSubagentRunsForRequester(requesterSessionKey).filter(
        (run) => !run.endedAt,
      );

      // Transform to agent status format
      const activeAgents = activeRuns.map((run) => ({
        runId: run.runId,
        childSessionKey: run.childSessionKey,
        requesterSessionKey: run.requesterSessionKey,
        parentRunId: run.parentRunId || undefined,
        taskDescription: `Processing request in ${run.spawnMode} mode`,
        startedAt: run.createdAt,
        elapsedMs: Date.now() - run.createdAt,
        state: "active" as const,
      }));

      const result: AgentStatusResult = {
        activeAgents,
        activeConnections: context.getActiveConnectionCount?.() ?? 0,
        timestamp: Date.now(),
      };

      respond(true, result);
    } catch (error) {
      respond(
        false,
        undefined,
        errorShape(
          ErrorCodes.INTERNAL_ERROR,
          `agent.status failed: ${error instanceof Error ? error.message : "unknown error"}`,
        ),
      );
    }
  },
};
