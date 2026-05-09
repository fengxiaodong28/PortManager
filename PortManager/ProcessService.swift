import Foundation

enum ProcessError: Error, LocalizedError {
    case commandFailed(String)
    case parseError(String)
    case killFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return "命令执行失败: \(msg)"
        case .parseError(let msg): return "解析失败: \(msg)"
        case .killFailed(let msg): return "结束进程失败: \(msg)"
        }
    }
}

class ProcessService {
    static let shared = ProcessService()

    func fetchListeningPorts() async throws -> [PortInfo] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-P", "-n", "-F", "pcnTu"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw ProcessError.parseError("无法读取输出")
        }

        if task.terminationStatus != 0 {
            throw ProcessError.commandFailed(output)
        }

        return parseLsofOutput(output)
    }

    private func parseLsofOutput(_ output: String) -> [PortInfo] {
        var ports: [PortInfo] = []
        var currentPid: Int?
        var currentName: String?
        var currentUser: String?
        var currentProtocol: String?

        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            guard line.count > 1 else { continue }
            let prefix = line.prefix(1)
            let value = String(line.dropFirst())

            switch prefix {
            case "p":
                currentPid = Int(value)
            case "c":
                currentName = value
            case "n":
                // n* 127.0.0.1:8080 or n* [::1]:8080 or n* *:8080
                if let port = extractPort(from: value) {
                    if let pid = currentPid,
                       let name = currentName {
                        let info = PortInfo(
                            port: port,
                            pid: pid,
                            processName: name,
                            protocolType: currentProtocol ?? "TCP",
                            user: currentUser ?? ""
                        )
                        ports.append(info)
                    }
                }
            case "T":
                if value.hasPrefix("ST=") {
                    // 协议状态
                }
            default:
                break
            }
        }

        // 去重：按 port + pid 组合去重
        var seen = Set<String>()
        return ports.filter { info in
            let key = "\(info.port)-\(info.pid)"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }.sorted { $0.port < $1.port }
    }

    private func extractPort(from address: String) -> Int? {
        // 处理各种格式: 127.0.0.1:8080, [::1]:8080, *:8080, IPv6地址]
        var str = address

        // 去掉IPv6前缀如果有的话
        if str.hasPrefix("[") {
            if let closingBracket = str.lastIndex(of: "]") {
                str = String(str[closingBracket...])
            }
        }

        // 找最后一个冒号
        if let colonIndex = str.lastIndex(of: ":") {
            let portStr = String(str[str.index(after: colonIndex)...])
            // 去掉可能的后缀如 (LISTEN)
            let cleanPort = portStr.components(separatedBy: CharacterSet(charactersIn: " (")).first ?? portStr
            return Int(cleanPort)
        }

        return nil
    }

    func killProcess(pid: Int) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/kill")
        task.arguments = ["-9", "\(pid)"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: data, encoding: .utf8) ?? "未知错误"
            throw ProcessError.killFailed(errorMsg)
        }
    }
}
