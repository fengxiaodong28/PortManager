import Foundation
import Combine

@MainActor
class PortManagerViewModel: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var filteredPorts: [PortInfo] = []
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var killConfirmPid: Int?
    @Published var killConfirmName: String?
    @Published var showKillConfirm: Bool = false
    @Published var showKillSuccess: Bool = false
    @Published var killedProcessName: String = ""

    private let service = ProcessService.shared

    var portCount: Int {
        filteredPorts.count
    }

    var uniqueProcessCount: Int {
        Set(filteredPorts.map { $0.processName }).count
    }

    var hasLoaded: Bool {
        lastUpdated != nil
    }

    func loadPorts() async {
        isLoading = true
        errorMessage = nil

        do {
            let newPorts = try await service.fetchListeningPorts()
            ports = newPorts
            applyFilter()
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() {
        Task {
            await loadPorts()
        }
    }

    func confirmKill(port: PortInfo) {
        killConfirmPid = port.pid
        killConfirmName = port.processName
        showKillConfirm = true
    }

    func executeKill() async {
        guard let pid = killConfirmPid else { return }
        let name = killConfirmName ?? ""

        do {
            try await service.killProcess(pid: pid)
            killedProcessName = name
            showKillSuccess = true
            await loadPorts()
        } catch {
            errorMessage = error.localizedDescription
        }

        showKillConfirm = false
        killConfirmPid = nil
        killConfirmName = nil
    }

    func cancelKill() {
        showKillConfirm = false
        killConfirmPid = nil
        killConfirmName = nil
    }

    private func applyFilter() {
        if searchText.isEmpty {
            filteredPorts = ports
            return
        }

        let lowercased = searchText.lowercased()
        filteredPorts = ports.filter { port in
            port.displayPort.contains(lowercased) ||
            port.processName.lowercased().contains(lowercased) ||
            port.displayPid.contains(lowercased)
        }
    }
}
