//
//  ProjectModels.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 23.10.2025.
//

import SwiftData
import Foundation

// MARK: - Project Model

@Model
final class Project {
    enum FileType: String, Codable {
        case audio
        case video
    }

    enum TaskType: String, Codable {
        case editing
        case transcribing
    }

    enum Status: String, Codable {
        case queued
        case started
        case failed
        case finished
    }

    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var fileType: FileType
    var taskType: TaskType
    var status: Status

    /// Длительность (в секундах) — только для аудио/видео editing
    var duration: Double?

    /// Путь к исходному локальному файлу (видео или аудио)
    var localFilePath: String?

    /// Результат (например, путь к сгенерированному файлу или текст)
    var result: String?

    /// Дата создания
    var createdAt: Date

    /// Название
    var name: String?
    
    /// Транскрипции и главы (nullable)
    @Relationship(deleteRule: .cascade) var transcriptions: [Transcription] = []
    @Relationship(deleteRule: .cascade) var summaryChapters: [SummaryChapter] = []

    // MARK: - Init

    init(
        id: UUID = UUID(),
        fileType: FileType,
        taskType: TaskType,
        status: Status = .queued,
        duration: Double? = nil,
        localFilePath: String? = nil,
        result: String? = nil
    ) {
        self.id = id
        self.fileType = fileType
        self.taskType = taskType
        self.status = status
        self.duration = duration
        self.localFilePath = localFilePath
        self.result = result
        self.createdAt = Date()
        self.name = localFilePath
    }
}

// MARK: - Submodels

@Model
final class Transcription {
    var speaker: String
    var text: String
    var start: Double
    var end: Double

    init(speaker: String, text: String, start: Double, end: Double) {
        self.speaker = speaker
        self.text = text
        self.start = start
        self.end = end
    }
}

@Model
final class SummaryChapter {
    var start: Double
    var title: String

    init(start: Double, title: String) {
        self.start = start
        self.title = title
    }
}

struct BackendResponse: Codable {
    let id, status: String
    let result: String?
    let transcriptions: [BackendTranscription]?
    let summaries: [String]?
    let summaryChapters: [BackendChapter]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case id, status, result, transcriptions, summaries
        case summaryChapters = "summary_chapters"
        case error
    }
}

// MARK: - SummaryChapter
struct BackendChapter: Codable {
    let start: Double
    let title: String
}

// MARK: - Transcription
struct BackendTranscription: Codable {
    let speaker, text: String
    let start, end: Double
}
