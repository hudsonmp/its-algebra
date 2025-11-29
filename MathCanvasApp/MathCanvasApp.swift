import SwiftUI
import PencilKit
import Supabase

@main
struct MathCanvasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                CanvasContainer(viewModel: viewModel)
                    .ignoresSafeArea()
                
                VStack {
                    LatexSidebar(latex: Binding(
                        get: { viewModel.currentLatex },
                        set: { viewModel.currentLatex = $0 }
                    ))
                    .padding(.top, 60)
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    ToolBar(viewModel: viewModel)
                        .padding(.bottom, 20)
                }
                
                if viewModel.isRecognizing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Math Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Recognize Math", systemImage: "doc.text") {
                            Task { await viewModel.recognizeMath() }
                        }
                        Button("Clear Canvas", systemImage: "trash", role: .destructive) {
                            viewModel.clear()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class AppViewModel: ObservableObject {
    @Published var drawing = PKDrawing()
    @Published var tool: PKTool = PKInkingTool(.pen, color: .black, width: 2)
    @Published var currentLatex = "Draw math to see LaTeX..."
    @Published var shouldSyncDrawing = false
    @Published var isRecognizing = false
    
    private var undoStack: [PKDrawing] = []
    private var redoStack: [PKDrawing] = []
    private var recognitionTask: Task<Void, Never>?
    
    func drawingDidChange(_ newDrawing: PKDrawing) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.drawing.strokes.count != newDrawing.strokes.count {
                self.undoStack.append(self.drawing)
                if self.undoStack.count > 30 { self.undoStack.removeFirst() }
                self.redoStack.removeAll()
            }
            self.drawing = newDrawing
            
            // Debounced recognition
            self.recognitionTask?.cancel()
            self.recognitionTask = Task {
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s debounce
                if !Task.isCancelled {
                    await self.recognizeMath()
                }
            }
        }
    }
    
    func recognizeMath() async {
        let strokes = drawing.strokes
        guard !strokes.isEmpty else {
            currentLatex = "Draw math to see LaTeX..."
            return
        }
        
        // Render drawing to image
        let bounds = drawing.bounds.insetBy(dx: -30, dy: -30)
        guard !bounds.isEmpty else { return }
        
        let image = drawing.image(from: bounds, scale: 3.0)
        guard let imageData = image.pngData() else { return }
        
        // Check API credentials
        guard !Config.mathpixAppId.isEmpty, !Config.mathpixAppKey.isEmpty else {
            currentLatex = "⚠️ Set MATHPIX_APP_ID and MATHPIX_APP_KEY"
            return
        }
        
        isRecognizing = true
        defer { isRecognizing = false }
        
        do {
            let latex = try await MathpixAPI.recognize(imageData: imageData)
            currentLatex = latex
        } catch {
            currentLatex = "Error: \(error.localizedDescription)"
        }
    }
    
    func toggleTool() {
        tool = (tool is PKEraserTool) 
            ? PKInkingTool(.pen, color: .black, width: 2) 
            : PKEraserTool(.vector)
    }
    
    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(drawing)
        drawing = prev
        shouldSyncDrawing = true
    }
    
    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(drawing)
        drawing = next
        shouldSyncDrawing = true
    }
    
    func clear() {
        undoStack.append(drawing)
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack.removeAll()
        drawing = PKDrawing()
        shouldSyncDrawing = true
        currentLatex = "Draw math to see LaTeX..."
    }
}

// MARK: - Mathpix API

enum MathpixAPI {
    static func recognize(imageData: Data) async throws -> String {
        let base64 = imageData.base64EncodedString()
        
        guard let url = URL(string: "https://api.mathpix.com/v3/text") else {
            throw MathpixError.apiError(-1)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.mathpixAppId, forHTTPHeaderField: "app_id")
        request.setValue(Config.mathpixAppKey, forHTTPHeaderField: "app_key")
        
        let body: [String: Any] = [
            "src": "data:image/png;base64,\(base64)",
            "formats": ["latex_simplified"],
            "data_options": ["include_latex": true]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw MathpixError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw MathpixError.unauthorized }
            if http.statusCode == 429 { throw MathpixError.rateLimited }
            throw MathpixError.apiError(http.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let latex = json?["latex_simplified"] as? String, !latex.isEmpty {
            return latex.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let text = json?["text"] as? String, !text.isEmpty {
            return text
        }
        
        return "No math detected"
    }
}

enum MathpixError: LocalizedError {
    case invalidResponse, unauthorized, rateLimited, apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response"
        case .unauthorized: return "Invalid API key"
        case .rateLimited: return "Rate limit exceeded"
        case .apiError(let code): return "API error (\(code))"
        }
    }
}
