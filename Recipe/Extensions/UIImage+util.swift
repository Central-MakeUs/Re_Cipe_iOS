//
//  UIImage+util.swift
//  Recipe
//
//  Created by 김민호 on 2023/08/04.
//

import UIKit

extension UIImage {
    func imageWithColor(color1: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color1.setFill()
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)
        
        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
//    func toBase64() -> String? {
//        guard let data = self.pngData() else { return nil }
//        return data.base64EncodedString()
//    }
    
    func toBase64() -> String? {
        // JPEG 퀄리티를 사용해 이미지를 압축
        guard let imageData = self.jpegData(compressionQuality: .zero) else {
            return nil
        }
        
        // 이미지 데이터를 Base64로 인코딩
        let base64String = imageData.base64EncodedString()
        
        return base64String
    }

}
