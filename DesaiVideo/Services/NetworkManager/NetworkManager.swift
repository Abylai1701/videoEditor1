//
//  NetworkManager.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 23.10.2025.
//

import Foundation
import Alamofire

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://aiaudioeditor.webberapp.shop/api"

    // MARK: - Create Task (POST /task)
    func createTask(
        fileURL: URL,
        fileType: String = "audio/m4a",
        appBundle: String = "com.yourapp.bundle",
        userId: String = "default_user",
        summarize: Bool = true,
        soundStudio: Bool = true,
        socialContent: Bool = false,
        exportTimestamps: Bool = false,
        removeDeadAir: Bool = false,
        muted: Bool = true,
        transcription: Bool = true,
        removeFillerWords: Bool = true,
        merge: Bool = false,
        video: Bool = false,
        exportFormat: String = "mp3"
    ) async throws -> BackendResponse {
        let url = "\(baseURL)/task"

        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { formData in
                    formData.append(Data(appBundle.utf8), withName: "app_bundle")
                    formData.append(Data(summarize.description.utf8), withName: "summarize")
                    formData.append(Data(exportFormat.utf8), withName: "export_format")
                    formData.append(Data(soundStudio.description.utf8), withName: "sound_studio")
                    formData.append(Data(socialContent.description.utf8), withName: "social_content")
                    formData.append(Data(exportTimestamps.description.utf8), withName: "export_timestamps")
                    formData.append(Data(removeDeadAir.description.utf8), withName: "remove_dead_air")
                    formData.append(Data(muted.description.utf8), withName: "muted")
                    formData.append(Data(userId.utf8), withName: "user_id")
                    formData.append(Data(transcription.description.utf8), withName: "transcription")
                    formData.append(Data(removeFillerWords.description.utf8), withName: "remove_filler_words")
                    formData.append(Data(merge.description.utf8), withName: "merge")
                    formData.append(Data(video.description.utf8), withName: "video")

                    // сам файл
                    formData.append(fileURL, withName: "file", fileName: fileURL.lastPathComponent, mimeType: fileType)
                },
                to: url
            )
            .validate(statusCode: 200..<300)
            .responseDecodable(of: BackendResponse.self) { response in
                switch response.result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Get Task Status (GET /task/{id})
    func fetchTaskStatus(taskId: UUID) async throws -> BackendResponse {
        let url = "\(baseURL)/task/\(taskId.uuidString)"

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .get)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: BackendResponse.self) { response in
                    switch response.result {
                    case .success(let result):
                        continuation.resume(returning: result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Download file (for result)
    func downloadFile(from urlString: String) async throws -> URL {
        let destination: DownloadRequest.Destination = { _, _ in
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        return try await withCheckedThrowingContinuation { continuation in
            AF.download(urlString, to: destination)
                .response { response in
                    if let fileURL = response.fileURL {
                        continuation.resume(returning: fileURL)
                    } else if let error = response.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NetworkError.invalidResponse("Empty file URL"))
                    }
                }
        }
    }
}

// MARK: - Error Enum
enum NetworkError: Error {
    case invalidResponse(String)
}
