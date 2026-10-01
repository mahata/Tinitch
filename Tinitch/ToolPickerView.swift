import SwiftUI

struct ToolPickerView: View {
    @Binding var selectedTool: Tool?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tools")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(Tool.allCases) { tool in
                Button {
                    selectedTool = selectedTool == tool ? nil : tool
                } label: {
                    Label(tool.title, systemImage: tool.systemImageName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTool == tool ? Color.accentColor.opacity(0.25) : .clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help(tool.hint)
            }

            if let selectedTool {
                Text(selectedTool.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ToolPickerView(selectedTool: .constant(.text))
        .frame(width: 180)
        .padding()
}
