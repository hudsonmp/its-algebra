import SwiftUI
import PencilKit

// MARK: - Canvas

struct CanvasContainer: UIViewRepresentable {
    @ObservedObject var viewModel: AppViewModel
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.tool = viewModel.tool
        canvas.backgroundColor = .white
        return canvas
    }
    
    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.tool = viewModel.tool
        if viewModel.shouldSyncDrawing {
            canvas.drawing = viewModel.drawing
            DispatchQueue.main.async { viewModel.shouldSyncDrawing = false }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(viewModel) }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var vm: AppViewModel
        init(_ vm: AppViewModel) { self.vm = vm }
        
        func canvasViewDrawingDidChange(_ canvas: PKCanvasView) {
            guard !vm.shouldSyncDrawing else { return }
            vm.drawingDidChange(canvas.drawing)
        }
    }
}

// MARK: - Toolbar

struct ToolBar: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var inkType = 0
    @State private var color: Color = .black
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<4) { i in
                Button {
                    inkType = i
                    updateTool()
                } label: {
                    Image(systemName: ["pencil.tip", "pencil", "highlighter", "eraser"][i])
                        .font(.title2)
                        .foregroundStyle(inkType == i ? .blue : .secondary)
                }
            }
            
            Divider().frame(height: 30)
            
            ColorPicker("", selection: $color)
                .labelsHidden()
                .onChange(of: color) { updateTool() }
            
            Divider().frame(height: 30)
            
            Button { viewModel.undo() } label: { Image(systemName: "arrow.uturn.backward") }
            Button { viewModel.redo() } label: { Image(systemName: "arrow.uturn.forward") }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private func updateTool() {
        let c = UIColor(color)
        switch inkType {
        case 0: viewModel.tool = PKInkingTool(.pen, color: c, width: 2)
        case 1: viewModel.tool = PKInkingTool(.pencil, color: c, width: 2)
        case 2: viewModel.tool = PKInkingTool(.marker, color: c, width: 10)
        case 3: viewModel.tool = PKEraserTool(.vector)
        default: break
        }
    }
}

// MARK: - LaTeX Sidebar

struct LatexSidebar: View {
    @Binding var latex: String
    @State private var isExpanded = true
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 8)
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LaTeX")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ScrollView {
                            Text(latex.isEmpty ? "Draw to see LaTeX..." : latex)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(12)
                    .frame(width: 280)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.trailing, 16)
        }
    }
}

