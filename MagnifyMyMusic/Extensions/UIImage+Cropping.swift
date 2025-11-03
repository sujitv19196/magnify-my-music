//
//  UIImage+Cropping.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import UIKit

extension UIImage {
    func cropped(to rect: CGRect) -> UIImage? {
        // rect is in normalized coordinates (0-1)
        let scaledRect = CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
        
        guard let cgImage = self.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}

