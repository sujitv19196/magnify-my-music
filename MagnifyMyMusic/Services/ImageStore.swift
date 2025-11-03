//
//  ImageStore.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import UIKit

class ImageStore {
    private var imagesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Images", isDirectory: true)
    }
    
    init() {
        try? FileManager.default.createDirectory(
            at: imagesURL, 
            withIntermediateDirectories: true
        )
    }
    
    func save(_ image: UIImage, documentName: String, index: Int) throws -> String {
        let safeName = documentName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .prefix(50)
        
        let filename = "\(safeName)_\(index).jpg"
        let url = imagesURL.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw ImageStoreError.compressionFailed
        }
        
        try data.write(to: url)
        return filename
    }
    
    func load(_ filename: String) throws -> UIImage {
        let url = imagesURL.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageStoreError.invalidImage
        }
        
        return image
    }
    
    func delete(_ filename: String) throws {
        let url = imagesURL.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: url)
    }
    
    func deleteAll(forDocumentName name: String) throws {
        let safeName = name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .prefix(50)
        
        let contents = try FileManager.default.contentsOfDirectory(
            at: imagesURL,
            includingPropertiesForKeys: nil
        )
        
        let documentImages = contents.filter { 
            $0.lastPathComponent.hasPrefix("\(safeName)_")
        }
        
        for url in documentImages {
            try FileManager.default.removeItem(at: url)
        }
    }
}

enum ImageStoreError: Error {
    case compressionFailed
    case invalidImage
}

