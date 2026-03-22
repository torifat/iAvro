import SwiftUI

@MainActor
final class CandidateViewModel: ObservableObject {
    @Published var candidates: [String] = []
    @Published var selectedIndex: Int = 0
}

struct CandidateView: View {
    @ObservedObject var viewModel: CandidateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.candidates.enumerated()), id: \.offset) { index, candidate in
                HStack(spacing: 6) {
                    Text(index < 9 ? "\(index + 1)" : " ")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(index == viewModel.selectedIndex ? .white : .secondary)
                        .frame(width: 18, alignment: .center)

                    Text(candidate)
                        .font(.system(size: 15))
                        .foregroundStyle(index == viewModel.selectedIndex ? .white : .primary)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(index == viewModel.selectedIndex ? Color.accentColor : Color.clear)
                )
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Candidates") {
    let vm = CandidateViewModel()
    vm.candidates = ["আমি", "এম", "অ্যাম", "আম", "আঁ"]
    vm.selectedIndex = 0
    return CandidateView(viewModel: vm)
        .frame(width: 200)
        .background(.regularMaterial)
}
