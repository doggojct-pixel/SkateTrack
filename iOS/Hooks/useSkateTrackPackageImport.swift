// [協作區] iOS/Hooks/useSkateTrackPackageImport.swift
// 用途：向 SwiftUI 暴露 Task-030d 多檔 .skatetrack 匯入預覽、選取與安全提交狀態。
// 委派至：SkateTrackPackageImportCoordinator；View 不直接讀檔、不碰 repository internals。

import Combine
import Foundation

@MainActor
final class SkateTrackPackageImportViewModel: ObservableObject {
    @Published private(set) var candidates: [SkateTrackImportCandidate] = []
    @Published var selectedCandidateIDs: Set<UUID> = []
    @Published private(set) var commitResults: [SkateTrackImportCommitResult] = []
    @Published private(set) var isPreparing = false
    @Published private(set) var isCommitting = false
    @Published var errorKey: String?

    private let coordinator: SkateTrackPackageImportCoordinator

    init(coordinator: SkateTrackPackageImportCoordinator = SkateTrackPackageImportCoordinator()) {
        self.coordinator = coordinator
    }

    var batchSummary: SkateTrackImportBatchSummary {
        SkateTrackImportBatchSummary(candidates: candidates)
    }

    var commitSummary: SkateTrackImportCommitSummary {
        SkateTrackImportCommitSummary(results: commitResults)
    }

    var selectedImportableCount: Int {
        candidates.filter { selectedCandidateIDs.contains($0.id) && $0.isImportable }.count
    }

    var hasPreparedCandidates: Bool {
        candidates.isEmpty == false || isPreparing
    }

    func prepareImport(from urls: [URL]) async {
        reset(keepStagingFiles: false)
        guard urls.isEmpty == false else {
            errorKey = "import.error.noFilesSelected"
            return
        }

        isPreparing = true
        let validatedCandidates = await coordinator.validatePackages(from: urls)
        candidates = validatedCandidates
        selectedCandidateIDs = Set(validatedCandidates.filter(\.isImportable).map(\.id))
        if validatedCandidates.isEmpty {
            errorKey = "import.error.noFilesSelected"
        }
        isPreparing = false
    }

    func toggleSelection(for candidate: SkateTrackImportCandidate) {
        guard candidate.isImportable else { return }
        if selectedCandidateIDs.contains(candidate.id) {
            selectedCandidateIDs.remove(candidate.id)
        } else {
            selectedCandidateIDs.insert(candidate.id)
        }
    }

    func selectAllImportable() {
        selectedCandidateIDs = Set(candidates.filter(\.isImportable).map(\.id))
    }

    func clearSelection() {
        selectedCandidateIDs.removeAll()
    }

    func commitSelectedCandidates() async {
        guard selectedImportableCount > 0 else {
            errorKey = "import.error.noImportableSelection"
            return
        }
        isCommitting = true
        errorKey = nil
        commitResults = await coordinator.commitSelectedPackages(
            candidates: candidates,
            selectedCandidateIDs: selectedCandidateIDs
        )
        isCommitting = false
    }

    func reset(keepStagingFiles: Bool = false) {
        candidates = []
        selectedCandidateIDs = []
        commitResults = []
        errorKey = nil
        isPreparing = false
        isCommitting = false
        if keepStagingFiles == false {
            coordinator.cleanupStagingDirectory()
        }
    }

}

@MainActor
func useSkateTrackPackageImport(
    coordinator: SkateTrackPackageImportCoordinator = SkateTrackPackageImportCoordinator()
) -> SkateTrackPackageImportViewModel {
    SkateTrackPackageImportViewModel(coordinator: coordinator)
}
