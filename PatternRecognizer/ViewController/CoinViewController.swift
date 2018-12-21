//
//  CoinViewController.swift
//  PatternRecognizer
//
//  Created by Alexandr Nadtoka on 10/30/18.
//  Copyright © 2018 kreatimont. All rights reserved.
//

import UIKit

class CoinViewController: UIViewController, Alertable {
    
    @IBOutlet weak var pickedImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageProcessingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var dilateButton: UIButton!
    @IBOutlet weak var erodeButton: UIButton!
    @IBOutlet weak var markButton: UIButton!
    
    @IBOutlet weak var changeBarButton: UIBarButtonItem!
    
    var originFulSizeImage: UIImage?
    var originImage: UIImage?
    let context = CIContext()
    var imageToolbox: ImageToolbox? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.changeBarButton.isEnabled = false
        setupUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    private func setupUI() {
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.barTintColor = UIColor.black.withAlphaComponent(0.5)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 18)!]
    }
    
    @IBAction func handleStart(_ sender: Any) {
        //NEW IMPL
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false

//        Dynamically show output from binary converting
//        DispatchQueue.global().async {
//            self.imageToolbox?.binaryImageDynamicaly(progress: { (currentImage, finished) in
//                DispatchQueue.main.async {
//                    self.pickedImageView.image = currentImage
//                    if finished {
//                        self.activityIndicator.stopAnimating()
//                        self.activityIndicator.isHidden = true
//                        self.startButton.isEnabled = true
//                    }
//                }
//            })
//        }
        
        DispatchQueue.global().async {
            let binaryImage = self.imageToolbox?.binaryImage
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
                if let outputImage = binaryImage {
                    self.pickedImageView.image = outputImage
                } else {
                    self.showAlert(title: nil, message: "Faild to create bw image");
                }
            }
        }
        

    }
    
    @IBAction func handlePickImage(_ sender: Any) {
        self.showPickerController()
    }
    
    @IBAction func handleChangeImage(_ sender: Any) {
        self.showPickerController()
    }
    
    @IBAction func handleDilate(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false
        
        DispatchQueue.global().async {
            let dilateImage = self.imageToolbox?.dilateImage
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
                if let outputImage = dilateImage {
                    self.pickedImageView.image = outputImage
                } else {
                    self.showAlert(title: nil, message: "Faild to create bw image");
                }
            }
        }
    }
    
    @IBAction func handleErode(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false
        
        DispatchQueue.global().async {
            let erodeImage = self.imageToolbox?.erodeImage
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
                if let outputImage = erodeImage {
                    self.pickedImageView.image = outputImage
                } else {
                    self.showAlert(title: nil, message: "Faild to create bw image");
                }
            }
        }
    }
    
    @IBAction func handleMark(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false
        
        DispatchQueue.global().async {
            let colored = self.imageToolbox?.colorLabeledImage
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
                if let outputImage = colored {
                    self.pickedImageView.image = outputImage
                } else {
                    self.showAlert(title: nil, message: "Faild to create bw image");
                }
            }
        }
    }
    
    @IBAction func handleCalclulateAmount(_ sender: Any) {
        
        DispatchQueue.global().async {
            if let diameters = self.imageToolbox?.diameters() {
                var amounts = [String: Int]()
                for (_ , diam) in diameters {
                    let name = self.coinName(from: diam)
                    if amounts[name] == nil {
                        amounts[name] = 1
                    } else {
                        amounts[name]! += 1
                    }
                }
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Coins amount", message: nil, preferredStyle: .actionSheet)
                    for amount in amounts {
                        alertController.addAction(UIAlertAction(title: "\(amount.key) - \(amount.value)", style: .default, handler: nil))
                    }
                    alertController.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: nil, message: "Faild to calc coins amount");
                }
            }
        }
        
    }
    
    @IBAction func handleAutomaticStart(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false
        
        DispatchQueue.global().async {
            _ = self.imageToolbox?.binaryImage
            _ = self.imageToolbox?.dilateImage
            _ = self.imageToolbox?.erodeImage
            _ = self.imageToolbox?.colorLabeledImage
            
            let diameters = self.imageToolbox?.diameters()
            let position = self.imageToolbox?.labelPositions()
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
            }
            guard let diam = diameters else {
                self.showAlert(title: nil, message: "Faild to calc diameters");
                return
            }
            if let positions = position {
                DispatchQueue.main.async {
                    
                    self.pickedImageView.image = self.originFulSizeImage
                    
                    for pos in positions {
                        
                        let origin = self.convertPointToImageViewGrid(pos.value)
                        let uiLabel = UILabel(frame: CGRect(origin: origin, size: CGSize(width: 60, height: 40)))
                        
                        uiLabel.numberOfLines = 0
                        uiLabel.lineBreakMode = .byWordWrapping
                        let name = self.coinName(from: diam[pos.key] ?? 0)
                        
                        uiLabel.attributedText = NSMutableAttributedString(string: "\(name)",
                            attributes: self.stroke(font: UIFont.systemFont(ofSize: 12, weight: .heavy),
                                                    strokeWidth: 4, insideColor: .white, strokeColor: .black))
                        self.pickedImageView.addSubview(uiLabel)
                        
                    }
                }
            }
        }
    }
    
    @IBAction func handleAutomaticStartWithOverlay(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false
        
        DispatchQueue.global().async {
            _ = self.imageToolbox?.binaryImage
            _ = self.imageToolbox?.dilateImage
            _ = self.imageToolbox?.erodeImage
            let colored = self.imageToolbox?.colorLabeledImage
            
            let diameters = self.imageToolbox?.diameters()
            let position = self.imageToolbox?.labelPositions()
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
            }
            guard let diam = diameters else {
                self.showAlert(title: nil, message: "Faild to calc diameters");
                return
            }
            if let positions = position {
                DispatchQueue.main.async {
                    
                    self.pickedImageView.image = self.originFulSizeImage
                    
                    if colored != nil {
                        let coloredImageView = UIImageView(frame: self.pickedImageView.bounds)
                        coloredImageView.image = colored
                        coloredImageView.alpha = 0.2
                        self.pickedImageView.addSubview(coloredImageView)
                    }
                    
                    
                    for pos in positions {
                        
                        let origin = self.convertPointToImageViewGrid(pos.value)
                        let uiLabel = UILabel(frame: CGRect(origin: origin, size: CGSize(width: 60, height: 40)))
                        
                        uiLabel.numberOfLines = 0
                        uiLabel.lineBreakMode = .byWordWrapping
                        var name = self.coinName(from: diam[pos.key] ?? 0)
                        name.append("\n\(diam[pos.key] ?? 0)")
                        
                        uiLabel.attributedText = NSMutableAttributedString(string: "\(name)",
                            attributes: self.stroke(font: UIFont.systemFont(ofSize: 12, weight: .heavy),
                                                    strokeWidth: 4, insideColor: .white, strokeColor: .black))
                        self.pickedImageView.addSubview(uiLabel)
                        
                    }
                }
            }
        }
    }
    
    @IBAction func handleClearToolbox(_ sender: Any) {
        guard let oldFullSize = self.originFulSizeImage else {
            return
        }
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.pickedImageView.subviews.forEach { $0.removeFromSuperview() }
            }
            var image = oldFullSize
            if image.size.height > 140 && image.size.width > 140 {
                image = ImageToolbox.resizeImage(image: image, targetSize: CGSize(width: 140, height: 140))
            }
            self.originImage = image
            let toolBox = ImageToolbox(image: image)
            DispatchQueue.main.async {
                self.changeBarButton.isEnabled = true
                self.imageProcessingView.isHidden = false
                self.activityIndicator.isHidden = true
                self.infoLabel.text = "size: \(image.size)"
                self.imageToolbox = toolBox
                self.pickedImageView.image = image
            }
        }
        
    }
    
    public func stroke(font: UIFont, strokeWidth: Float, insideColor: UIColor, strokeColor: UIColor) -> [NSAttributedString.Key: Any]{
        return [
            NSAttributedString.Key.strokeColor : strokeColor,
            NSAttributedString.Key.foregroundColor : insideColor,
            NSAttributedString.Key.strokeWidth : -strokeWidth,
            NSAttributedString.Key.font : font
        ]
    }
    
    @IBAction func handleTapDiameters(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.startButton.isEnabled = false
        
        DispatchQueue.global().async {
            let diameters = self.imageToolbox?.diameters()
            let position = self.imageToolbox?.labelPositions()
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.startButton.isEnabled = true
                guard let diam = diameters else {
                    self.showAlert(title: nil, message: "Faild to calc diameters");
                    return
                }
                if let positions = position {
                    DispatchQueue.main.async {
                        for pos in positions {
                            
                            let origin = self.convertPointToImageViewGrid(pos.value)
                            let uiLabel = UILabel(frame: CGRect(origin: origin, size: CGSize(width: 60, height: 12)))
                            uiLabel.numberOfLines = 2
                            let name = "\(diam[pos.key] ?? 0)"
                            uiLabel.attributedText = NSMutableAttributedString(string: "\(name)",
                                attributes: self.stroke(font: UIFont.systemFont(ofSize: 12, weight: .heavy),
                                                                                                strokeWidth: 4, insideColor: .white, strokeColor: .black))
                            self.pickedImageView.addSubview(uiLabel)
                            
                        }
                    }
                }
                
            }
        }
    }
    //MARK: - private methods
    
    private func coinName(from diam: Double) -> String {
        switch diam {
        case 9..<14:
            return "10 коп."
        case 14..<17:
            return "25 коп."
        case 17..<17.9:
            return "50 коп."
        case 17.9..<24:
            return "5 коп."
        default:
            return ""
        }
    }
    
    private func showPickerController() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = .black
        var isCamera = false
        let actionOnPick = {
            alertController.dismiss(animated: true, completion: nil)
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = isCamera ? .camera : .photoLibrary
            imagePickerController.delegate = self
            self.present(imagePickerController, animated: true, completion: nil)
        }
        let cameraAction = UIAlertAction(title: "Take photo", style: .default) { (_) in
            isCamera = true
            actionOnPick()
        }
        let libraryAction = UIAlertAction(title: "Pick from library", style: .default) { (_) in
            isCamera = false
            actionOnPick()
        }
        alertController.addAction(cameraAction)
        alertController.addAction(libraryAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Create Rect
    
    private func convertPointToImageViewGrid(_ point: CGPoint) -> CGPoint {
        guard let imageSize = self.originImage?.size else {
            return .zero
        }
        let scaleWidth = self.pickedImageView.frame.width / imageSize.width
        let scaleHeight = self.pickedImageView.frame.height / imageSize.height
        
        let aspect = min(scaleWidth, scaleHeight)
        
        let imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        
        var newX = point.y * aspect
        var newY = point.x * aspect
        
        //added centering inside image view
        newX += (self.pickedImageView.frame.width - imageRect.size.width) / 2
        newY += (self.pickedImageView.frame.height - imageRect.size.height) / 2
        
        return CGPoint(x: newX, y: newY)
    }
    
    private func calculateRectOfImageInImageView(imageView: UIImageView) -> CGRect {
        let imageViewSize = imageView.frame.size
        guard let imageSize = imageView.image?.size else {
            return .zero
        }
        
        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        
        let aspect = fmin(scaleWidth, scaleHeight)
        
        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2
        
        // Add imageView offset
        imageRect.origin.x += imageView.frame.origin.x
        imageRect.origin.y += imageView.frame.origin.y
        
        return imageRect
    }
    
}


extension CoinViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.pickedImageView.subviews.forEach { $0.removeFromSuperview() }
            }
            var image = image
            self.originFulSizeImage = image
            if image.size.height > 140 && image.size.width > 140 {
                image = ImageToolbox.resizeImage(image: image, targetSize: CGSize(width: 140, height: 140))
            }
            self.originImage = image
            let toolBox = ImageToolbox(image: image)
            DispatchQueue.main.async {
                self.changeBarButton.isEnabled = true
                self.imageProcessingView.isHidden = false
                self.activityIndicator.isHidden = true
                self.infoLabel.text = "size: \(image.size)"
                self.imageToolbox = toolBox
                self.pickedImageView.image = image
            }
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
    
}



