import Foundation

actor TaskPoller {
    static let shared = TaskPoller()
    private var active: [UUID: Task<Void, Never>] = [:]

    func startPolling(
        id: UUID,
        interval: TimeInterval = 5,
        timeout: TimeInterval = 600,
        fileType: Project.FileType,
        taskType: Project.TaskType,
        localFilePath: String?,
        duration: Double?,
        checkStatus: @escaping (UUID) async throws -> BackendResponse
    ) {
        // Не запускаем дубликаты
        guard active[id] == nil else {
            print("⚠️ Polling already active for \(id)")
            return
        }

        active[id] = Task {
            let start = Date()
            var lastResponse: BackendResponse?

            defer {
                active[id] = nil
                print("🛑 Polling finished for \(id)")
            }

            while !Task.isCancelled, Date().timeIntervalSince(start) < timeout {
                do {
                    let resp = try await checkStatus(id)
                    lastResponse = resp

                    await MainActor.run {
                        ProjectManager.shared.handleBackendResponse(
                            resp,
                            fileType: fileType,
                            taskType: taskType,
                            localFilePath: localFilePath,
                            duration: duration
                        )
                    }

                    // Если задача завершилась — выходим
                    if resp.status == "finished" || resp.status == "failed" {
                        break
                    }

                } catch {
                    print("⚠️ Polling error for \(id):", error)
                }

                // Ожидание перед следующим запросом
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }

            // MARK: 🧹 Очистка по завершению

            // Если истек timeout и статус не "finished"
            if Date().timeIntervalSince(start) >= timeout,
               lastResponse?.status != "finished" {
                await MainActor.run {
                    if let project = ProjectManager.shared.fetchByIdSync(id) {
                        ProjectManager.shared.delete(project)
                        NotificationCenter.default.post(
                            name: .cancelTask,
                            object: nil,
                            userInfo: ["id": id]
                        )
                        print("⏰ Timeout reached — deleted unfinished project \(id)")
                    }
                }
            }
        }
    }

    func stop(id: UUID) {
        active[id]?.cancel()
        active[id] = nil
        print("🛑 Stopped polling for \(id)")
    }
}
