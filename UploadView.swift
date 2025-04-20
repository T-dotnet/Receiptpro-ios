import SwiftUI
import UIKit

struct UploadView: View {
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var ocrError: String?
    @State private var extractedReceipt: Receipt?
    @State private var showEditSheet = false
    @State private var showSuccess = false

    @StateObject private var supabase = SupabaseManager.shared

    var body: some View {
        VStack {
            if isUploading {
                ProgressView("Processing...")
                    .padding()
            } else if let receipt = extractedReceipt, showEditSheet {
                EditReceiptView(receipt: receipt) { updated in
                    Task {
                        await saveReceipt(updated)
                    }
                    showEditSheet = false
                }
            } else {
                Spacer()
                Button(action: { showImagePicker = true }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text("Select or Capture Receipt")
                            .font(.title2)
                            .padding(.top, 8)
                    }
                }
                .accessibility(identifier: "UploadButton")
                .padding()
                if let error = uploadError {
                    Text("Upload error: \(error)")
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                if let error = ocrError {
                    Text("OCR error: \(error)")
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                if showSuccess {
                    Text("Receipt saved successfully!")
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .accessibility(identifier: "UploadView")
    }

    func loadImage() {
        guard let image = inputImage else { return }
        Task {
            isUploading = true
            uploadError = nil
            ocrError = nil
            showSuccess = false
            do {
                // 1. Upload image to Supabase Storage
                let imageUrl = try await supabase.uploadReceiptImage(image: image)
                // 2. Call OCR API (placeholder)
                let ocrText = try await callOCRAPI(imageUrl: imageUrl)
                // 3. Parse OCR text into Receipt
                let parsed = parseReceipt(from: ocrText)
                extractedReceipt = parsed
                showEditSheet = true
            } catch {
                uploadError = error.localizedDescription
            }
            isUploading = false
        }
    }

    func callOCRAPI(imageUrl: String) async throws -> String {
        // Placeholder: POST to https://example.com/ocr with { "image_url": imageUrl }
        guard let url = URL(string: "https://example.com/ocr") else {
            throw NSError(domain: "OCR", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid OCR endpoint"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["image_url": imageUrl]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "OCR", code: 0, userInfo: [NSLocalizedDescriptionKey: "OCR API failed"])
        }
        // Assume response is { "text": "..." }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let text = json?["text"] as? String else {
            throw NSError(domain: "OCR", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid OCR response"])
        }
        return text
    }

    func parseReceipt(from text: String) -> Receipt {
        // Placeholder: naive parsing, real implementation should use regex/ML
        // We'll just fill with dummy data for now
        return Receipt(
            id: UUID().uuidString,
            user_id: supabase.session?.user.id ?? "",
            date: ISO8601DateFormatter().string(from: Date()),
            amount: 0.0,
            category: "Uncategorized",
            status: "New",
            merchant: "Unknown",
            notes: text,
            created_at: ISO8601DateFormatter().string(from: Date())
        )
    }

    func saveReceipt(_ receipt: Receipt) async {
        isUploading = true
        uploadError = nil
        ocrError = nil
        do {
            try await supabase.insertReceipt(receipt)
            showSuccess = true
            extractedReceipt = nil
        } catch {
            uploadError = error.localizedDescription
        }
        isUploading = false
    }
}

// MARK: - UIKit Image Picker Bridge
struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Preview
struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}