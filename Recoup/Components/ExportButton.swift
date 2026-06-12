import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

/// CSV exported lazily — the temp file is only written when the user shares.
struct CSVFile: Transferable {
    var filename: String
    var header: [String]
    var rows: [[String]]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let url = try CSVExporter.writeTempFile(named: file.filename, header: file.header, rows: file.rows)
            return SentTransferredFile(url)
        }
    }
}

struct ExportButton: View {
    var filename: String
    var header: [String]
    var rows: [[String]]

    var body: some View {
        ShareLink(
            item: CSVFile(filename: filename, header: header, rows: rows),
            preview: SharePreview(filename, image: Image(systemName: "tablecells"))
        ) {
            Label("Export CSV", systemImage: "square.and.arrow.up")
        }
        .disabled(rows.isEmpty)
    }
}
