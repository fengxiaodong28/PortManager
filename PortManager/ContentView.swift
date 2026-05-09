import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = PortManagerViewModel()
    @State private var hoverPid: Int?

    var body: some View {
        VStack(spacing: 0) {
            // 头部区域
            headerView

            Divider()

            // 搜索框
            searchBar

            // 列表区域
            listView

            Divider()

            // 底部区域
            footerView
        }
        .frame(width: 420, height: 520)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            if !viewModel.hasLoaded {
                viewModel.refresh()
            }
        }
    }

    // MARK: - 头部
    private var headerView: some View {
        HStack {
            Image(systemName: "network")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("端口管理器")
                    .font(.headline)
                Text("查看并管理占用端口的进程")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { viewModel.refresh() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isLoading)
            .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
            .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.caption)

            TextField("搜索端口、进程名或PID...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 列表
    private var listView: some View {
        Group {
            if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        viewModel.refresh()
                    }
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else if viewModel.filteredPorts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text(viewModel.searchText.isEmpty ? "没有端口被占用" : "未找到匹配结果")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredPorts) { port in
                            PortRow(
                                port: port,
                                isHovered: hoverPid == port.pid,
                                onHover: { isHover in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        hoverPid = isHover ? port.pid : nil
                                    }
                                },
                                onKill: {
                                    viewModel.confirmKill(port: port)
                                }
                            )

                            if port.id != viewModel.filteredPorts.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
        .overlay(
            Group {
                if viewModel.showKillConfirm {
                    killConfirmOverlay
                }
                if viewModel.showKillSuccess {
                    killSuccessOverlay
                }
            }
        )
    }

    // MARK: - 杀掉进程确认弹层
    private var killConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)

                Text("确认结束进程?")
                    .font(.headline)

                Text("进程 \"\(viewModel.killConfirmName ?? "")\" (PID: \(viewModel.killConfirmPid ?? 0)) 将被强制结束")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("取消") {
                        viewModel.cancelKill()
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(BorderedButtonStyle())

                    Button("结束进程") {
                        Task {
                            await viewModel.executeKill()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.red)
                }
            }
            .padding(20)
            .frame(width: 300)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }

    // MARK: - 成功提示
    private var killSuccessOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("已结束 \"\(viewModel.killedProcessName)'")
                    .font(.callout)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .shadow(radius: 4)
            )
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    viewModel.showKillSuccess = false
                }
            }
        }
    }

    // MARK: - 底部
    private var footerView: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.isLoading ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)
                Text(viewModel.isLoading ? "刷新中..." : "\(viewModel.portCount) 个端口 · \(viewModel.uniqueProcessCount) 个进程")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let lastUpdated = viewModel.lastUpdated {
                Text(formatTime(lastUpdated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                NSApp.terminate(nil)
            }) {
                Image(systemName: "power")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("退出应用")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "更新于 \(formatter.string(from: date))"
    }
}

// MARK: - 单行视图
struct PortRow: View {
    let port: PortInfo
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onKill: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 端口标签
            Text(port.displayPort)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .frame(width: 55, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(port.processName)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("PID: \(port.displayPid)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("·")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(port.protocolType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 关闭按钮
            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(isHovered ? .red : Color.clear)
                    .background(
                        Circle()
                            .fill(isHovered ? Color.red.opacity(0.1) : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(isHovered ? Color.accentColor.opacity(0.06) : Color.clear)
        .onHover(perform: onHover)
    }
}

#Preview {
    ContentView()
}
