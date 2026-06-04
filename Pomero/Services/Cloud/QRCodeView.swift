import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// Renders a string (typically a CloudKit share URL) as a scannable QR code.
/// Shared by the watch and iPhone targets.
struct QRCodeView: View {
    let string: String

    var body: some View {
        if let cgImage = Self.makeQRCode(from: string) {
            Image(decorative: cgImage, scale: 1)
                .interpolation(.none)   // keep the code crisp when scaled up
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }

    private static let context = CIContext()

    static func makeQRCode(from string: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}
