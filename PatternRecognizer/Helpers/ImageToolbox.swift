//
//  ImageToolbox.swift
//  PatternRecognizer
//
//  Created by Alexandr Nadtoka on 11/7/18.
//  Copyright © 2018 kreatimont. All rights reserved.
//

import UIKit

struct Pixel: Equatable {
    private var rgba: UInt32
    
    var red: UInt8 {
        return UInt8((rgba >> 24) & 255)
    }
    
    var green: UInt8 {
        return UInt8((rgba >> 16) & 255)
    }
    
    var blue: UInt8 {
        return UInt8((rgba >> 8) & 255)
    }
    
    var alpha: UInt8 {
        return UInt8((rgba >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        rgba = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    
    static func ==(lhs: Pixel, rhs: Pixel) -> Bool {
        return lhs.rgba == rhs.rgba
    }
}

class ImageToolbox {
    
    let dx = [1, 0, -1, 0]
    let dy = [0, 1, 0, -1]
    
    let originUIImage: UIImage
    
    let imageWidth: Int
    let imageHeight: Int
    
    let context: CGContext
    let pixels: UnsafeMutablePointer<Pixel>
    let labels: UnsafeMutablePointer<UInt32>
    
    init?(image: UIImage) {
        self.originUIImage = image
        
        let imageref = image.cgImage!
        let width = imageref.width
        let height = imageref.height
        
        self.imageWidth = width
        self.imageHeight = height
        
        // create new bitmap context
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = Pixel.bitmapInfo
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        
        self.context = context
        
        // draw image to context
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        context.draw(imageref, in: rect)
        
        
        // manipulate binary data
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return nil
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: width * height)
        self.pixels = pixels
        
        self.labels = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
    }
    
    var binaryImage: UIImage? {
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return nil
        }
     
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: imageWidth * imageHeight)
     
        DispatchQueue.concurrentPerform(iterations: self.imageHeight) { row in
            for col in 0 ..< self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                
                let green = Float(pixels[offset].green)
                let blue = Float(pixels[offset].blue)
                let alpha = pixels[offset].alpha
                
                var luminance: UInt8
                if green > (255 / 2) {
                    luminance = 0
                } else {
                    luminance = 255
                }
                
                pixels[offset] = Pixel(red: luminance, green: luminance, blue: luminance, alpha: alpha)
            }
        }
        // return the image
        
        guard let outputImage = context.makeImage() else {
            print("[ImageToolbox] failedToCreate outputImage from context")
            return nil
        }
        return UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation)
    }
    
    func binaryImageDynamicaly(progress: ((_ output: UIImage, _ finished: Bool) -> ())?) {
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: imageWidth * imageHeight)
        
        DispatchQueue.concurrentPerform(iterations: self.imageHeight) { row in
            for col in 0 ..< self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                
//                let red = Float(pixels[offset].red)
                let green = Float(pixels[offset].green)
//                let blue = Float(pixels[offset].blue)
                let alpha = pixels[offset].alpha
                
                var luminance: UInt8
                
                if green > (255 / 2) {
                    luminance = 0
                } else {
                    luminance = 255
                }
                
                pixels[offset] = Pixel(red: luminance, green: luminance, blue: luminance, alpha: alpha)
                guard let outputImage = context.makeImage() else {
                    print("[ImageToolbox] failedToCreate outputImage from context")
                    return
                }
                progress?(UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation), false)
            }
        }
        // return the image
        
        guard let outputImage = context.makeImage() else {
            print("[ImageToolbox] failedToCreate outputImage from context")
            return
        }
        progress?(UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation), true)
//        return UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation)
    }
    
    var dilateImage: UIImage? {
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return nil
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: imageWidth * imageHeight)
        
        DispatchQueue.concurrentPerform(iterations: self.imageHeight) { row in
            for col in 0 ..< self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let red = pixels[offset].red
                let green = Float(pixels[offset].green)
                let blue = pixels[offset].blue
                let alpha = pixels[offset].alpha
                
                if green == 255 {
                    let prevXPixelOffset = Int((row - 1) * self.imageWidth + col)
                    let prevYPixelOffset = Int(row * self.imageWidth + (col - 1))
                    let nextXPixelOffset = Int((row + 1)  * self.imageWidth + col)
                    let nextYPixelOffset = Int(row * self.imageWidth + (col + 1))
                    
                    if row > 0 && pixels[prevXPixelOffset].green == 0 {
                        pixels[prevXPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                    if col > 0 && pixels[prevYPixelOffset].green == 0 {
                        pixels[prevYPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                    if (row + 1) < self.imageWidth && pixels[nextXPixelOffset].green == 0 {
                        pixels[nextXPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                    if (col + 1) < self.imageHeight && pixels[nextYPixelOffset].green == 0 {
                        pixels[nextYPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                }
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: self.imageHeight) { row in
            for col in 0 ..< self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let red = pixels[offset].red
                let green = Float(pixels[offset].green)
                let blue = pixels[offset].blue
                let alpha = pixels[offset].alpha
                
                if green == 2 {
                    pixels[offset] = Pixel(red: red, green: 255, blue: blue, alpha: alpha)
                }
            }
        }
        // return the image
        
        guard let outputImage = context.makeImage() else {
            print("[ImageToolbox] failedToCreate outputImage from context")
            return nil
        }
        return UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation)
    }
    
    var erodeImage: UIImage? {
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return nil
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: imageWidth * imageHeight)
        
        DispatchQueue.concurrentPerform(iterations: self.imageHeight) { row in
            for col in 0 ..< self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let red = pixels[offset].red
                let green = Float(pixels[offset].green)
                let blue = pixels[offset].blue
                let alpha = pixels[offset].alpha
                
                if green == 0 {
                    let prevXPixelOffset = Int((row - 1) * self.imageWidth + col)
                    let prevYPixelOffset = Int(row * self.imageWidth + (col - 1))
                    let nextXPixelOffset = Int((row + 1)  * self.imageWidth + col)
                    let nextYPixelOffset = Int(row * self.imageWidth + (col + 1))
                    
                    if row > 0 && pixels[prevXPixelOffset].green == 255 {
                        pixels[prevXPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                    if col > 0 && pixels[prevYPixelOffset].green == 255 {
                        pixels[prevYPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                    if (row + 1) < self.imageWidth && pixels[nextXPixelOffset].green == 255 {
                        pixels[nextXPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                    if (col + 1) < self.imageHeight && pixels[nextYPixelOffset].green == 255 {
                        pixels[nextYPixelOffset] = Pixel(red: red, green: 2, blue: blue, alpha: alpha)
                    }
                }
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: self.imageHeight) { row in
            for col in 0 ..< self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let red = pixels[offset].red
                let green = Float(pixels[offset].green)
                let blue = pixels[offset].blue
                let alpha = pixels[offset].alpha
                
                if green == 2 {
                    pixels[offset] = Pixel(red: 0, green: 0, blue: 0, alpha: alpha)
                }
            }
        }
        // return the image
        
        guard let outputImage = context.makeImage() else {
            print("[ImageToolbox] failedToCreate outputImage from context")
            return nil
        }
        return UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation)
    }
    
    func diameters() -> [UInt32: Double] {
        
        var squares = [UInt32: Int]()
        
        for row in 0..<self.imageHeight {
            
            for col in 0..<self.imageWidth {
                
                let offset = Int(row * self.imageWidth + col)
                let label = self.labels[offset]
                if label != 0 {
                    
                    if squares[label] == nil {
                       squares[label] = 1
                    } else {
                       squares[label]! += 1
                    }
                    
                }
                
            }
            
        }
        
        var diameters = [UInt32: Double]()
        
        for square in squares {
            diameters[square.key] = sqrt(Double(square.value) / Double.pi) * 2
        }
        
        return diameters
    }
    
    func labelPositions() -> [UInt32: CGPoint] {
        var positions = [UInt32: CGPoint]()
        
        for row in 0..<self.imageHeight {
            for col in 0..<self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let label = self.labels[offset]
                
                if label != 0 {
                    if positions[label] == nil {
                        positions[label] = CGPoint(x: row, y: col)
                    }
                }
            }
        }
        return positions
    }
    
    var colorLabeledImage: UIImage? {
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return nil
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: imageWidth * imageHeight)
        
        self.labels.assign(repeating: 0, count: imageWidth * imageHeight)
        
        var label: UInt32 = 0
        for row in 0..<self.imageHeight {
            for col in 0..<self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                if self.labels[offset] == 0 && self.pixels[offset].green != 0 {
                    label += 1
                    depthFirstSearch(row: row, col: col, label: label)
                }
            }
        }
        
        for row in 0..<self.imageHeight {
            for col in 0..<self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let labeledPixel = pixel(for: self.labels[offset])
                pixels[offset] = labeledPixel
            }
        }
        
        guard let outputImage = context.makeImage() else {
            print("[ImageToolbox] failedToCreate outputImage from context")
            return nil
        }
        return UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation)
    }
    
    //MARK: - my implementation of label algorithm(very slow - 1000x1000 img takes more than 10min on iPhone 6s) use two steps(label + merging intersects figures)
    var colorLabeledImageOptimized: UIImage? {
        guard let buffer = context.data else {
            print("[ImageToolbox] failed to create buffer from context.data")
            return nil
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: imageWidth * imageHeight)
        
        self.labels.assign(repeating: 0, count: imageWidth * imageHeight)
        
        var figuresCoords = [UInt32: [CGPoint]]()
        
        for row in 0..<self.imageHeight {
            for col in 0..<self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                
                let isWhite = self.pixels[offset].green > (255 / 2)
                
                var isWrited = false
                
                var writedLabel: UInt32     = 1
                
                if isWhite {
                    
                    for (label, coords) in figuresCoords {
                        
                        let inThisFigure = coords.contains { self.isConnected(point: $0, with: CGPoint(x: row, y: col)) }
                        if inThisFigure {
                            figuresCoords[label]?.append(CGPoint(x: row, y: col))
                            isWrited = true
                            writedLabel = label
                            break
                        }
                        
                    }
                    
                    if !isWrited {
                        let newIndex = UInt32(figuresCoords.count + 1)
                        figuresCoords[newIndex] = [CGPoint(x: row, y: col)]
                        writedLabel = UInt32(figuresCoords.count)
                    }
                    
                    
                } else {
                    writedLabel = 0
                }
                
                self.labels[offset] = writedLabel
            }
        }
        
        
        var intersectsPairs = [UInt32: UInt32]()
        
        for (label, coords) in figuresCoords {
            
            for (otherLabel, otherCoords) in figuresCoords.prefix(figuresCoords.count + 1) {
                var intersects = false
                
                for coord in coords {
                    
                    intersects = otherCoords.contains{ self.isConnected(point: $0, with: coord) }
                    
                    if intersects {
                        if label != otherLabel && (!intersectsPairs.keys.contains(label) && !intersectsPairs.values.contains(label)) {
                            intersectsPairs[label] = otherLabel
                        }
                        break
                    }
                    
                }
                if intersects {
                    continue
                }
                
            }
            
        }
        
        for pair in intersectsPairs {
            if let pointsToRename = figuresCoords[pair.value] {
                for pointToRename in  pointsToRename {
                    let offset = Int(Int(pointToRename.x) * self.imageWidth + Int(pointToRename.y))
                    self.labels[offset] = pair.key
                }
            }
        }
        
        for row in 0..<self.imageHeight {
            for col in 0..<self.imageWidth {
                let offset = Int(row * self.imageWidth + col)
                let labeledPixel = pixel(for: self.labels[offset])
                pixels[offset] = labeledPixel
            }
        }
        
        guard let outputImage = context.makeImage() else {
            print("[ImageToolbox] failedToCreate outputImage from context")
            return nil
        }
        return UIImage(cgImage: outputImage, scale: self.originUIImage.scale, orientation: self.originUIImage.imageOrientation)
    }
    
    private func isConnected(point: CGPoint, with: CGPoint) -> Bool {
        return (abs(point.x - with.x) <= 1) && (abs(point.y - with.y) <= 1)
    }
    
    //MARK: RECURSIVE -- error, try to fix
    func widthSearch(row: Int, col: Int, label: UInt32) -> Int {
        if (row < 0 || row == self.imageWidth) { return 0 }
        if (col < 0 || col == self.imageHeight) { return 0 }
        let offset = Int(row * self.imageWidth + col)
        if self.labels[offset] == 0 { return 0 }
        let currentWidth = widthSearch(row: row - 1, col: col, label: label) + widthSearch(row: row + 1, col: col, label: label)
        return currentWidth
    }
    
    //MARK: RECURSIVE LABEL
    private func depthFirstSearch(row: Int, col: Int, label: UInt32) {
        
        if (row < 0 || row == self.imageWidth) { return }
        if (col < 0 || col == self.imageHeight) { return }
        let width = self.imageWidth
        let offset = Int(row * width + col)
        if (self.labels[offset] != 0 || self.pixels[offset].green == 0) { return }
        
        self.labels[offset] = label
        
        for i in 0...3 {
            depthFirstSearch(row: row + dx[i], col: col + dy[i], label: label)
        }
    }
    
    private func tailDepthFirstSearch(row: Int, col: Int, label: UInt32) {
        let offset = Int(row * imageWidth + col)
    }
    
    //MARK: HELPER METHOD FOR LABEL COLOR
    private func pixel(for number: UInt32) -> Pixel {
        switch number {
        case 0:
            return Pixel(red: 0, green: 0, blue: 0, alpha: 255)
        case 1:
            return Pixel(red: 0, green: 255, blue: 0, alpha: 255)
        case 2:
            return Pixel(red: 0, green: 0, blue: 255, alpha: 255)
        case 3:
            return Pixel(red: 255, green: 0, blue: 0, alpha: 255)
        case 4:
            return Pixel(red: 123, green: 123, blue: 255, alpha: 255)
        case 5:
            return Pixel(red: 234, green: 134, blue: 12, alpha: 255)
        case 6:
            return Pixel(red: 0, green: 255, blue: 163, alpha: 255)
        case 7:
            return Pixel(red: 144, green: 144, blue: 144, alpha: 255)
        case 8:
            return Pixel(red: 241, green: 212, blue: 3, alpha: 255)
        case 9:
            return Pixel(red: 133, green: 169, blue: 199, alpha: 255)
        case 10:
            return Pixel(red: 27, green: 140, blue: 38, alpha: 255)
        case 11:
            return Pixel(red: 140, green: 74, blue: 27, alpha: 255)
        case 12:
            return Pixel(red: 98, green: 0, blue: 255, alpha: 255)
        case 13:
            return Pixel(red: 0, green: 255, blue: 255, alpha: 255)
        case 14:
            return Pixel(red: 219, green: 255, blue: 0, alpha: 255)
        case 15:
            return Pixel(red: 167, green: 176, blue: 113, alpha: 255)
        case 16:
            return Pixel(red: 113, green: 176, blue: 161, alpha: 255)
        default:
            return Pixel(red: 255, green: 255, blue: 255, alpha: 255)
        }
    }
    
    //MARK: HELPER METHOD FOR RESIZING IMAGE
    class func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
}
