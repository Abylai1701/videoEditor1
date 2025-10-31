extension Array where Element == Project {
    
    func filterByFileType(_ fileType: Segment) -> [Project] {
        filter { project in
            switch fileType {
            case .audio:
                return project.fileType == .audio
            case .video:
                return project.fileType == .video
            }
        }
    }
    
    func filterBySearch(_ query: String) -> [Project] {
        guard !query.isEmpty else { return self }
        return filter { project in
            (project.name ?? "")
                .localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterByFilters(
        _ status: StatusOption,
        _ duration: DurationOption,
        _ date: DateOption
    ) -> [Project] {
        var result = self
        
        // 🟢 Статус
        switch status {
        case .edited:
            result = result.filter { $0.taskType == .editing && $0.status == .finished }
        case .transcribed:
            result = result.filter { $0.taskType == .transcribing && $0.status == .finished }
        case .inProgress:
            result = result.filter { $0.status == .queued || $0.status == .started }
        case .all:
            break
        }

        // 🟣 Длительность
        switch duration {
        case .zeroToFive:
            result = result.filter { ($0.duration ?? 0) < 300 } // < 5 мин
        case .fiveToTen:
            result = result.filter { (300...600).contains($0.duration ?? 0) } // 5–10 мин
        case .tenToThirty:
            result = result.filter { (600...1800).contains($0.duration ?? 0) } // 10–30 мин
        case .all:
            break
        }

        // 🔵 Дата
        switch date {
        case .newestFirst:
            result.sort(by: { $0.createdAt > $1.createdAt })
        case .oldestFirst:
            result.sort(by: { $0.createdAt < $1.createdAt })
        }

        return result
    }
}
