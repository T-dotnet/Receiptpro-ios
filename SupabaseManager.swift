//  SupabaseManager.swift
//  ios-dashboard-shell

import Foundation
import Supabase
import Combine

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // Replace with your Supabase project URL and anon key
    private let supabaseUrl = URL(string: "https://your-project.supabase.co")!
    private let supabaseKey = "your-anon-key"

    let client: SupabaseClient

    @Published var session: Session?
    @Published var isAuthenticated: Bool = false
    @Published var authError: String?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseKey)
        observeSession()
        restoreSession()
    }

    private func observeSession() {
        client.auth.sessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.session = session
                self?.isAuthenticated = (session != nil)
            }
            .store(in: &cancellables)
    }

    private func restoreSession() {
        // Supabase Swift SDK persists session by default, so just check current session
        if let session = client.auth.session {
            self.session = session
            self.isAuthenticated = true
        } else {
            self.session = nil
            self.isAuthenticated = false
        }
    }

    func signUp(email: String, password: String) {
        authError = nil
        Task {
            do {
                let _ = try await client.auth.signUp(email: email, password: password)
            } catch {
                DispatchQueue.main.async {
                    self.authError = error.localizedDescription
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        authError = nil
        Task {
            do {
                let _ = try await client.auth.signIn(email: email, password: password)
            } catch {
                DispatchQueue.main.async {
                    self.authError = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        authError = nil
        Task {
            do {
                try await client.auth.signOut()
            } catch {
                DispatchQueue.main.async {
                    self.authError = error.localizedDescription
                }
            }
        }
    }
extension SupabaseManager {
    /// Uploads a UIImage to Supabase Storage (bucket: "receipts"). Returns the public URL.
    func uploadReceiptImage(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data."])
        }
        let filename = UUID().uuidString + ".jpg"
        let bucket = "receipts"
        let path = filename
        // Upload to storage
        _ = try await client.storage.from(bucket: bucket).upload(path: path, file: imageData, options: FileOptions(contentType: "image/jpeg"))
        // Get public URL
        let publicURL = client.storage.from(bucket: bucket).getPublicUrl(path: path)
        return publicURL.absoluteString
    }
}
extension SupabaseManager {
    /// Inserts a Receipt into the "expenses" table
    func insertReceipt(_ receipt: Receipt) async throws {
        _ = try await client.from("expenses").insert(values: [
            "id": receipt.id,
            "user_id": receipt.user_id,
            "date": receipt.date,
            "amount": receipt.amount,
            "category": receipt.category,
            "status": receipt.status,
            "merchant": receipt.merchant ?? "",
            "notes": receipt.notes ?? "",
            "created_at": receipt.created_at ?? ""
        ]).execute()
    }
extension SupabaseManager {
    /// Fetches receipts/expenses for the current user
    func fetchExpenses() async throws -> [Receipt] {
        guard let userId = self.session?.user.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        let response = try await client
            .from("expenses")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
        if let data = response.decoded(to: [Receipt].self) {
            return data
        } else {
            throw NSError(domain: "Supabase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode expenses."])
        }
    }
}

}