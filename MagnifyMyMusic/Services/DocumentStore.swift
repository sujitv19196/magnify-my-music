//
//  DocumentStore.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/14/26.
//

import UIKit

// MARK: - DocumentManifest

struct DocumentManifest: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
}

// MARK: - DocumentStore

/// Manages persistence of `.magnify` document bundles.
///
/// Bundle layout:
/// ```
/// Documents/MagnifyDocuments/
///   {uuid}.magnify/
///     manifest.json      <- lightweight metadata (for list view)
///     document.json      <- full document tree (metadata + segments + markers)
///     images/
///       page_0.jpg
/// ```
@Observable
class DocumentStore {
    
    var documentList: [DocumentManifest] = []
        
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    /// Root directory for all document bundles.
    private var baseURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MagnifyDocuments", isDirectory: true)
    }
        
    init() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        loadManifests()
    }
        
    func bundleURL(for id: UUID) -> URL {
        baseURL.appendingPathComponent("\(id.uuidString).magnify", isDirectory: true)
    }
    
    private func manifestURL(for id: UUID) -> URL {
        bundleURL(for: id).appendingPathComponent("manifest.json")
    }
    
    private func documentURL(for id: UUID) -> URL {
        bundleURL(for: id).appendingPathComponent("document.json")
    }
    
    private func imagesURL(for id: UUID) -> URL {
        bundleURL(for: id).appendingPathComponent("images", isDirectory: true)
    }
    
    /// Scans for `.magnify` bundles and reads each `manifest.json` to populate `documentList`.
    /// Falls back to reading `document.json` if manifest is missing.
    func loadManifests() {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            documentList = []
            return
        }
        
        let bundles = contents.filter { $0.pathExtension == "magnify" }
        
        documentList = bundles.compactMap { bundleURL -> DocumentManifest? in
            let manifestFile = bundleURL.appendingPathComponent("manifest.json")
            let documentFile = bundleURL.appendingPathComponent("document.json")
            
            // Try manifest.json first (fast path)
            if let data = try? Data(contentsOf: manifestFile),
               let manifest = try? decoder.decode(DocumentManifest.self, from: data) {
                return manifest
            }
            
            // Fall back to document.json (regenerate manifest)
            if let data = try? Data(contentsOf: documentFile),
               let doc = try? decoder.decode(SheetMusicDocument.self, from: data) {
                let manifest = DocumentManifest(
                    id: doc.id, name: doc.name,
                    createdAt: doc.createdAt, modifiedAt: doc.modifiedAt
                )
                try? encoder.encode(manifest).write(to: manifestFile)
                return manifest
            }
            
            return nil
        }
        
    }
    
    func loadDocument(id: UUID) throws -> SheetMusicDocument {
        let url = documentURL(for: id)
        let data = try Data(contentsOf: url)
        return try decoder.decode(SheetMusicDocument.self, from: data)
    }
        
    /// Persists the full document and updates the manifest.
    /// Creates the bundle directory and images subdirectory if needed.
    func save(_ document: SheetMusicDocument) throws {
        let bundle = bundleURL(for: document.id)
        let images = imagesURL(for: document.id)
        
        try fileManager.createDirectory(at: bundle, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: images, withIntermediateDirectories: true)
        
        document.modifiedAt = Date()
        
        let docData = try encoder.encode(document)
        try docData.write(to: documentURL(for: document.id), options: .atomic)
        
        let manifest = DocumentManifest(
            id: document.id, name: document.name,
            createdAt: document.createdAt, modifiedAt: document.modifiedAt
        )
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: manifestURL(for: document.id), options: .atomic)
        
        // Update in-memory list
        if let index = documentList.firstIndex(where: { $0.id == document.id }) {
            documentList[index] = manifest
        } else {
            documentList.insert(manifest, at: 0)
        }
    }
    
    /// Removes the entire `.magnify` bundle directory from disk and the list.
    func delete(id: UUID) throws {
        let bundle = bundleURL(for: id)
        if fileManager.fileExists(atPath: bundle.path) {
            try fileManager.removeItem(at: bundle)
        }
        documentList.removeAll { $0.id == id }
    }
        
    /// Saves a JPEG image into the document's bundle with a UUID-based filename.
    /// - Returns: The filename (e.g. "A3F2...jpg") to store in `imagePaths`.
    @discardableResult
    func saveImage(_ image: UIImage, to documentId: UUID) throws -> String {
        let images = imagesURL(for: documentId)
        try fileManager.createDirectory(at: images, withIntermediateDirectories: true)
        
        let filename = "\(UUID().uuidString).jpg"
        let url = images.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw DocumentStoreError.imageCompressionFailed
        }
        
        try data.write(to: url, options: .atomic)
        return filename
    }
    
    /// Loads an image from the document's bundle.
    func loadImage(_ filename: String, from documentId: UUID) throws -> UIImage {
        let url = imagesURL(for: documentId).appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        
        guard let image = UIImage(data: data) else {
            throw DocumentStoreError.invalidImage
        }
        return image
    }
    
    /// Deletes a single image from the document's bundle.
    func deleteImage(_ filename: String, from documentId: UUID) throws {
        let url = imagesURL(for: documentId).appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}

enum DocumentStoreError: LocalizedError {
    case imageCompressionFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed: "Failed to compress image to JPEG"
        case .invalidImage: "File is not a valid image"
        }
    }
}
