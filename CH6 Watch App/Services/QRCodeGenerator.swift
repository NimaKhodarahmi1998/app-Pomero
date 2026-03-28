import SwiftUI

/// Generates a visual QR-like grid pattern from a string.
/// CoreImage is not available on watchOS, so this creates a simple
/// visual code that's recognizable but not scannable.
/// The actual pairing uses the 6-character text code.
enum QRCodeGenerator {
    static func generate(from string: String, size: CGFloat = 100) -> some View {
        let grid = generatePattern(from: string)
        let cellSize = size / CGFloat(grid.count)

        return Canvas { context, _ in
            for (row, cols) in grid.enumerated() {
                for (col, filled) in cols.enumerated() {
                    if filled {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        context.fill(Path(rect), with: .color(.white))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private static func generatePattern(from string: String, gridSize: Int = 9) -> [[Bool]] {
        let bytes = Array(string.utf8)
        var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Border
        for i in 0..<gridSize {
            grid[0][i] = true
            grid[gridSize - 1][i] = true
            grid[i][0] = true
            grid[i][gridSize - 1] = true
        }

        // Fill inner cells based on string hash
        var index = 0
        for row in 1..<(gridSize - 1) {
            for col in 1..<(gridSize - 1) {
                let byte = bytes[index % bytes.count]
                grid[row][col] = (byte &+ UInt8(row * col)) % 3 != 0
                index += 1
            }
        }

        return grid
    }
}
