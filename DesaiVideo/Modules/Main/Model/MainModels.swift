//
//  MainModels.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import Foundation

enum ProcessSegmentedControlItem {
    case edit, transcribe
}

import SwiftUI

struct VideoItem: Transferable {
    
    // MARK: - Public Properties
    
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) {
            SentTransferredFile($0.url)
        } importing: { receivedFile in
            let fileName = receivedFile.file.lastPathComponent
            let url = URL.temporaryDirectory.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.copyItem(at: receivedFile.file, to: url)
            return VideoItem(url: url)
        }
    }
}
