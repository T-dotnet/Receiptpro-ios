import SwiftUI
import Supabase
import Combine

// MARK: - Receipt Model
struct Receipt: Identifiable, Codable, Equatable {
    let id: String
    let user_id: String
    let date: String // ISO8601 string, can be parsed to Date if needed
    let amount: Double
    let category: String
    let status: String
    let merchant: String?
    let notes: String?
    let created_at: String?
}

// MARK: - ViewModel
class ReceiptListViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var editingReceipt: Receipt?
    @Published var showEditSheet: Bool = false
    @Published var isDeleting: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let client = SupabaseManager.shared.client

    init() {
        fetchReceipts()
        // Listen for auth changes to refetch
        SupabaseManager.shared.$isAuthenticated
            .sink { [weak self] isAuth in
                if isAuth { self?.fetchReceipts() }
                else { self?.receipts = [] }
            }
            .store(in: &cancellables)
    }

    func fetchReceipts() {
        guard SupabaseManager.shared.isAuthenticated else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let response = try await client
                    .from("expenses")
                    .select()
                    .order("date", ascending: false)
                    .execute()
                if let data = response.decoded(to: [Receipt].self) {
                    DispatchQueue.main.async {
                        self.receipts = data
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = "Failed to decode receipts."
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func deleteReceipt(_ receipt: Receipt) {
        isDeleting = true
        error = nil
        Task {
            do {
                _ = try await client
                    .from("expenses")
                    .delete()
                    .eq("id", value: receipt.id)
                    .execute()
                DispatchQueue.main.async {
                    self.receipts.removeAll { $0.id == receipt.id }
                    self.isDeleting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isDeleting = false
                }
            }
        }
    }

    func updateReceipt(_ receipt: Receipt) {
        isLoading = true
        error = nil
        Task {
            do {
                _ = try await client
                    .from("expenses")
                    .update([
                        "date": receipt.date,
                        "amount": receipt.amount,
                        "category": receipt.category,
                        "status": receipt.status,
                        "merchant": receipt.merchant ?? "",
                        "notes": receipt.notes ?? ""
                    ])
                    .eq("id", value: receipt.id)
                    .execute()
                DispatchQueue.main.async {
                    if let idx = self.receipts.firstIndex(where: { $0.id == receipt.id }) {
                        self.receipts[idx] = receipt
                    }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - View
struct ViewView: View {
    @StateObject private var viewModel = ReceiptListViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading receipts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            viewModel.fetchReceipts()
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.receipts.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No receipts found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.receipts) { receipt in
                            ReceiptRow(receipt: receipt,
                                       onEdit: { viewModel.editingReceipt = receipt; viewModel.showEditSheet = true },
                                       onDelete: { viewModel.deleteReceipt(receipt) })
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { idx in
                                let receipt = viewModel.receipts[idx]
                                viewModel.deleteReceipt(receipt)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Receipts")
            .toolbar {
                EditButton()
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                if let editing = viewModel.editingReceipt {
                    EditReceiptView(receipt: editing) { updated in
                        viewModel.updateReceipt(updated)
                        viewModel.showEditSheet = false
                    }
                }
            }
        }
        .accessibility(identifier: "ViewView")
    }
}

// MARK: - Receipt Row
struct ReceiptRow: View {
    let receipt: Receipt
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.merchant ?? "Unknown Merchant")
                    .font(.headline)
                Text(receipt.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Status: \(receipt.status)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("$\(String(format: "%.2f", receipt.amount))")
                    .font(.title3)
                    .bold()
                Text(formattedDate(receipt.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(BorderlessButtonStyle())
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }

    func formattedDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        return iso
    }
}

// MARK: - Edit Receipt View
struct EditReceiptView: View {
    @State var receipt: Receipt
    var onSave: (Receipt) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Merchant", text: Binding(
                        get: { receipt.merchant ?? "" },
                        set: { receipt.merchant = $0 }
                    ))
                    TextField("Category", text: $receipt.category)
                    TextField("Status", text: $receipt.status)
                    TextField("Amount", value: $receipt.amount, formatter: NumberFormatter())
                    TextField("Date (YYYY-MM-DD)", text: $receipt.date)
                    TextField("Notes", text: Binding(
                        get: { receipt.notes ?? "" },
                        set: { receipt.notes = $0 }
                    ))
                }
            }
            .navigationTitle("Edit Receipt")
            .navigationBarItems(
                leading: Button("Cancel") { onSave(receipt) },
                trailing: Button("Save") { onSave(receipt) }
            )
        }
    }
}

// MARK: - Preview
struct ViewView_Previews: PreviewProvider {
    static var previews: some View {
        ViewView()
    }
}