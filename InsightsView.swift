import SwiftUI

struct AnalysisResult: Identifiable {
    let id = UUID()
    let summary: String
    let totalSpent: Double
    let topCategory: String
    let chartData: [String: Double]
    let analyzedAt: Date
}

struct InsightsView: View {
    @ObservedObject private var supabase = SupabaseManager.shared

    @State private var expenses: [Receipt] = []
    @State private var isLoadingExpenses = false
    @State private var expensesError: String?
    
    @State private var isAnalyzing = false
    @State private var analysisResult: AnalysisResult?
    @State private var analysisError: String?
    @State private var pollingActive = false
    @State private var showAnalysisSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if isLoadingExpenses {
                    ProgressView("Loading expenses...")
                        .padding()
                } else if let error = expensesError {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            loadExpenses()
                        }
                        .padding(.top, 8)
                    }
                } else if expenses.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No expenses found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    // Summary Cards
                    if let result = analysisResult {
                        VStack(spacing: 12) {
                            HStack {
                                summaryCard(title: "Total Spent", value: String(format: "$%.2f", result.totalSpent), color: .blue)
                                summaryCard(title: "Top Category", value: result.topCategory, color: .green)
                            }
                            .padding(.horizontal)
                            Text(result.summary)
                                .font(.body)
                                .padding(.horizontal)
                            // Simple Chart
                            ChartView(data: result.chartData)
                                .frame(height: 180)
                                .padding(.horizontal)
                            Text("Analyzed at \(formattedDate(result.analyzedAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Run AI Analysis to get insights on your spending.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }

                Spacer()
                
                // Analysis Button
                if supabase.isAuthenticated {
                    Button(action: {
                        triggerAnalysis()
                    }) {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 8)
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Run AI Analysis")
                            .bold()
                    }
                    .disabled(isAnalyzing || expenses.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 8)
                } else {
                    Text("Sign in to analyze your expenses.")
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }

                if let error = analysisError {
                    Text("Analysis Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }
                if showAnalysisSuccess {
                    Text("Analysis complete!")
                        .foregroundColor(.green)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Insights")
            .onAppear {
                loadExpenses()
            }
            .accessibility(identifier: "InsightsView")
        }
    }

    // MARK: - Helpers

    func loadExpenses() {
        isLoadingExpenses = true
        expensesError = nil
        Task {
            do {
                let data = try await supabase.fetchExpenses()
                DispatchQueue.main.async {
                    self.expenses = data
                    self.isLoadingExpenses = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.expensesError = error.localizedDescription
                    self.isLoadingExpenses = false
                }
            }
        }
    }

    func triggerAnalysis() {
        isAnalyzing = true
        analysisError = nil
        showAnalysisSuccess = false
        analysisResult = nil
        pollingActive = true

        // Simulate backend API call and polling for completion
        Task {
            // Simulate network delay for starting analysis
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            pollForAnalysisResult(attempt: 0)
        }
    }

    func pollForAnalysisResult(attempt: Int) {
        // Simulate polling (max 5 attempts, 1s apart)
        guard attempt < 5 else {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.pollingActive = false
                self.analysisError = "Analysis timed out. Please try again."
            }
            return
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            // Simulate analysis completion on 2nd attempt
            if attempt >= 1 {
                DispatchQueue.main.async {
                    self.analysisResult = mockAnalysisResult(from: expenses)
                    self.isAnalyzing = false
                    self.pollingActive = false
                    self.showAnalysisSuccess = true
                }
            } else {
                pollForAnalysisResult(attempt: attempt + 1)
            }
        }
    }

    func mockAnalysisResult(from expenses: [Receipt]) -> AnalysisResult {
        let total = expenses.reduce(0) { $0 + $1.amount }
        let categoryTotals = Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        let topCategory = categoryTotals.max(by: { $0.value < $1.value })?.key ?? "N/A"
        let summary = "You spent a total of $\(String(format: "%.2f", total)) across \(expenses.count) receipts. Your top category is \(topCategory)."
        return AnalysisResult(
            summary: summary,
            totalSpent: total,
            topCategory: topCategory,
            chartData: categoryTotals,
            analyzedAt: Date()
        )
    }

    func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Simple Chart View (Bar Chart)
struct ChartView: View {
    let data: [String: Double]

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data.sorted(by: { $0.key < $1.key }), id: \.key) { category, value in
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: barHeight(value: value, maxHeight: geometry.size.height))
                        Text(category)
                            .font(.caption2)
                            .rotationEffect(.degrees(-45))
                            .frame(width: 40, height: 30, alignment: .top)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func barHeight(value: Double, maxHeight: CGFloat) -> CGFloat {
        let maxValue = data.values.max() ?? 1
        return CGFloat(value / maxValue) * (maxHeight - 30)
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
    }
}