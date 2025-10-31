//
//  FileStorage.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import Foundation

/// Типы файловых хранилищ
enum FileStorageType {
    case documents, temporary
}

final class FileStorage {

    // MARK: - Private Properties

    private let fileManager: FileManager = .default

    // MARK: - Public Methods

    func getFileURL(for fileName: String, storage: FileStorageType) throws -> URL {
        let directoryURL = try directoryURL(storage)
        return directoryURL.appendingPathComponent(fileName)
    }

    func copyFile(from url: URL, to storage: FileStorageType, with fileName: String) throws -> URL {
        let fileURL = try getFileURL(for: fileName, storage: storage)
        try removeFileIfExists(at: fileURL)
        try fileManager.copyItem(at: url, to: fileURL)
        return fileURL
    }

    func removeFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func removeFileIfExists(at url: URL) throws {
        guard hasFile(at: url) else { return }
        try fileManager.removeItem(at: url)
    }

    func hasFile(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Private Helpers

    private func directoryURL(_ type: FileStorageType) throws -> URL {
        switch type {
        case .documents:
            try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        case .temporary:
            fileManager.temporaryDirectory
        }
    }
}
