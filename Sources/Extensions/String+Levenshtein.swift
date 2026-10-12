import Foundation

extension String {
    func levenshteinDistance(to other: String) -> Int {
        let selfChars = Array(self.unicodeScalars)
        let otherChars = Array(other.unicodeScalars)
        let n = selfChars.count
        let m = otherChars.count

        guard n != 0, m != 0 else { return max(n, m) }

        var previousRow = Array(0...m)
        var currentRow = [Int](repeating: 0, count: m + 1)

        for i in 1...n {
            currentRow[0] = i
            for j in 1...m {
                let cost = selfChars[i - 1] == otherChars[j - 1] ? 0 : 1
                currentRow[j] = min(
                    min(previousRow[j] + 1, currentRow[j - 1] + 1),
                    previousRow[j - 1] + cost
                )
            }
            swap(&previousRow, &currentRow)
        }
        return previousRow[m]
    }
}
