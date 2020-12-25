//
//  DocumentView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import SwiftUI

struct DocumentFile<Document> {
    @Binding var document: Document
}

class NSDocumentWindow<Document, Content>: NSWindow where Content: View, Document: NSDocument {
    let content: (DocumentFile<Document>) -> Content
    let document: Document

    init(document: Document, @ViewBuilder editor: @escaping (DocumentFile<Document>) -> Content) {
        self.content = editor
        self.document = document
        
        super.init(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        isReleasedWhenClosed = false
        styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
        title = "title placeholder"
        contentView = NSHostingView(rootView: content(DocumentFile(document: .init() {
            self.document
        } set: { document in
            print(self.document)
        })))
    }
}

struct NSDocumentGroup<Document, Content>: Scene where Content: View, Document: NSDocument {
    let content: (DocumentFile<Document>) -> Content
    let document: Document

    init(newDocument: Document, @ViewBuilder editor: @escaping (DocumentFile<Document>) -> Content) {
        self.content = editor
        self.document = newDocument
    }

    var body: some Scene {
        WindowGroup {
            content(DocumentFile(document: .init() {
                document
            } set: { document in
                print(document)
            }))
        }
    }
}
