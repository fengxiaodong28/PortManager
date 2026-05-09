import Foundation

struct PortInfo: Identifiable, Hashable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let protocolType: String
    let user: String

    var displayPort: String {
        "\(port)"
    }

    var displayPid: String {
        "\(pid)"
    }
}
