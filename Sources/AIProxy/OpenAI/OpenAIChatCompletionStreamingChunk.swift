//
//  OpenAIChatCompletionStreamingChunk.swift
//
//
//  Created by Lou Zell on 8/17/24.
//

import Foundation

public struct OpenAIChatCompletionChunk: Decodable {
    /// A list of chat completion choices. Can contain more than one elements if
    /// OpenAIChatCompletionRequestBody's `n` property is greater than 1. Can also be empty for
    /// the last chunk, which contains usage information only.
    public let choices: [OpenAIChunkChoice]

    /// This property is nil for all chunks except for the last chunk, which contains the token
    /// usage statistics for the entire request.
    public let usage: OpenAIChatUsage?
}

public struct OpenAIChunkChoice: Codable {
    public let delta: OpenAIChunkDelta
    public let finishReason: String?

    private enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

public struct OpenAIChunkDelta: Codable {
    public let role: String?
    public let content: String?
}

extension OpenAIChatCompletionChunk {
    /// Creates a ChatCompletionChunk from a streamed line of the /v1/chat/completions response
    internal static func from(line: String) -> Self? {
        guard line.hasPrefix("data: ") else {
            aiproxyLogger.warning("Received unexpected line from aiproxy: \(line)")
            return nil
        }

        guard line != "data: [DONE]" else {
            aiproxyLogger.debug("Streaming response has finished")
            return nil
        }

        guard let chunkJSON = line.dropFirst(6).data(using: .utf8),
              let chunk = try? JSONDecoder().decode(OpenAIChatCompletionChunk.self, from: chunkJSON) else
        {
            aiproxyLogger.warning("Received unexpected JSON from aiproxy: \(line)")
            return nil
        }

        // aiproxyLogger.debug("Received a chunk: \(line)")
        return chunk
    }
}
