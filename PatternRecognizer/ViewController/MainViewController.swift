//
//  ViewController.swift
//  PatternRecognizer
//
//  Created by Alexandr Nadtoka on 10/24/18.
//  Copyright © 2018 kreatimont. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    var kern: Double = 2.6
    var fontSize: CGFloat = 6
    var textColor = UIColor.black
    var hightlight = false
    
    var isDrawingText = false {
        didSet {
            if !Thread.isMainThread {
                DispatchQueue.main.async {
                    self.textView.isEditable = !self.isDrawingText
                }
            } else {
                DispatchQueue.main.async {
                    self.textView.isEditable = !self.isDrawingText
                }
            }
            
        }
    }
    
    var objects = [Int: [CGPoint]]()
    var labelsMatrix = [[Int]](repeating: [Int](repeating: 0, count: 40), count: 40)
    
    @IBOutlet weak var squareButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var fontSlider: UISlider!
    @IBOutlet weak var kernSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    private lazy var textView: UITextView = {
        let _textView = UITextView()
        _textView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        _textView.isEditable = false
        return _textView
    }()
    
    private var sectionInsets: UIEdgeInsets {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsets(top: 16.0, left: 32.0, bottom: 16.0, right: 32.0)
        } else {
            return UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let _collectionView = UICollectionView(frame: self.imageView.frame)
        _collectionView.delegate = self
        _collectionView.dataSource = self
        return _collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.infoLabel.text = "Width: \(40); Height: \(40)"
        self.squareButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }
    
    //MARK: -setup ui
    
    private func setupUI() {
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.barTintColor = UIColor.black.withAlphaComponent(0.5)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 18)!]
        
        textView.frame = self.imageView.frame
        self.view.addSubview(textView)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    //MARK: -actions
    
    @IBAction func handleChangeTap(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func handleSwitchColor(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.textColor = UIColor.white
            break
        case 1:
            self.textColor = UIColor.black
            break
        case 2:
            self.textColor = UIColor.red
            break
        case 3:
            self.textColor = UIColor.green
            break
        case 4:
            self.textColor = UIColor.blue
            break
        default: break
        }
        if !self.isDrawingText {
            self.reloadTextView()
        }
    }
    
    @IBAction func handleCalculateSquareTap(_ sender: UIButton) {
        let squares = self.calculateSquares().sorted { (first, second) -> Bool in
            return first.key < second.key
        }
        let message = ""
        let alertViewController = UIAlertController(title: "Squares", message: message, preferredStyle: .actionSheet)
        for item in squares {
            let action = UIAlertAction(title: "\(item.key): \(item.value)", style: .default, handler: nil)
            alertViewController.addAction(action)
        }
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    @IBAction func handleHightlightFigures(_ sender: UISwitch) {
        self.hightlight = sender.isOn
        if !self.isDrawingText {
            self.reloadTextView()
        }
        
    }
    
    @IBAction func handleTouchDownInfoButton(_ sender: UIButton) {
        self.textView.isHidden = true
    }
    
    @IBAction func handleTouchUpButton(_ sender: UIButton) {
        self.textView.isHidden = false
    }
    
    @IBAction func handlePixelMatrixTap(_ sender: Any) {
        if !self.isDrawingText {
            readBitmap(fileName: "test_image", ext: "bmp")
        }
    }
    
    @IBAction func handleFontSliderChanged(_ sender: UISlider) {
        self.fontSize = CGFloat(sender.value)
        if !self.isDrawingText {
            self.reloadTextView()
        }
    }
    
    @IBAction func handleKernSliderChanged(_ sender: UISlider) {
        self.kern = Double(sender.value)
        if !self.isDrawingText {
            self.reloadTextView()
        }
    }

    //MARK: -helper methods
    
    private func reloadTextView() {
        let newText = self.textView.attributedText.string
        var attrString = NSMutableAttributedString(string: newText, attributes: [NSAttributedString.Key.kern : self.kern, NSAttributedString.Key.font: UIFont.systemFont(ofSize: self.fontSize), NSAttributedString.Key.foregroundColor: self.textColor])
        
        if self.hightlight {
            for label in self.objects.keys {
                self.hightlight(string: "\(label)", attrString: &attrString)
            }
        }
        
        self.textView.attributedText = attrString
    }
    
    private func updateText(string: String) {
        let newText = string
    
        let fontWeight = (self.hightlight && (Int(string) ?? 0) != 0) ? UIFont.Weight.heavy : UIFont.Weight.regular
        let color = self.hightlight ? self.colorFor(index: Int(string) ?? 0) : self.textColor
        let attrString = NSMutableAttributedString(string: newText, attributes: [NSAttributedString.Key.kern : self.kern, NSAttributedString.Key.font: UIFont.systemFont(ofSize: self.fontSize, weight: fontWeight), NSAttributedString.Key.foregroundColor: color])
        
        let newAttrString = (self.textView.attributedText.mutableCopy() as! NSMutableAttributedString)
        newAttrString.append(attrString)
        self.textView.attributedText = newAttrString
    }
    
    private func hightlight(string: String, attrString: inout NSMutableAttributedString) {
        let inputLength = attrString.string.count
        let searchString = string
        let searchLength = searchString.count
        var range = NSRange(location: 0, length: attrString.length)
        
        while (range.location != NSNotFound) {
            range = (attrString.string as NSString).range(of: searchString, options: [], range: range)
            if (range.location != NSNotFound) {
                attrString.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: self.fontSize, weight: .heavy),
                                          NSAttributedString.Key.foregroundColor: self.colorFor(index: Int(string)!)], range: NSRange(location: range.location, length: searchLength))
                range = NSRange(location: range.location + range.length, length: inputLength - (range.location + range.length))
            }
        }
    }
    
    private func colorFor(index: Int) -> UIColor {
        switch index {
        case 0:
            return UIColor.red
        case 1:
            return UIColor.blue
        case 2:
            return UIColor.green
        case 3:
            return UIColor.magenta
        case 4:
            return UIColor.yellow
        case 5:
            return UIColor.orange
        case 6:
            return UIColor.purple
        case 7:
            return UIColor.brown
        case 8:
            return UIColor.black
        default:
            return UIColor.cyan
        }
    }
    
    //MARK: -image processing
    
    private func readBitmap(fileName: String, ext: String) {
        self.squareButton.isEnabled = false
        self.textView.attributedText = NSAttributedString(string: "")
        DispatchQueue.global().async {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("failed to get resource url for :\(fileName)")
                return
            }
            guard let data = try? Data(contentsOf: url) else {
                print("failed to get data from url: \(url.absoluteString)")
                return
            }
            guard let image = UIImage(data: data) else {
                print("failed to get image from data")
                return
            }
            guard let pixelData = image.cgImage?.dataProvider?.data else {
                print("failed to get pixel data from image")
                return
            }
            guard let pixelArray = CFDataGetBytePtr(pixelData) else {
                print("failed to get pixel array from pixel data")
                return
            }
            
            DispatchQueue.main.async {
                self.textView.isHidden = false
            }
            
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            self.isDrawingText = true
            
            self.objects = [Int: [CGPoint]]()
            
            for row in 0..<width {
                for column in 0..<height {
                    let pixelInfo: Int = ((row * width) + column) * 4
                    let r = CGFloat(pixelArray[pixelInfo+0]) / CGFloat(255.0)
                    let g = CGFloat(pixelArray[pixelInfo+1]) / CGFloat(255.0)
                    let b = CGFloat(pixelArray[pixelInfo+2]) / CGFloat(255.0)
                    let a = CGFloat(pixelArray[pixelInfo+3]) / CGFloat(255.0)
                    print("data[\(row)][\(column)] = \((r,g,b,a))")
                    let number = (r < 0.15 && g < 0.15 && b < 0.15) ? 0 : 1
                    
                    let currentPoint = CGPoint(x: row, y: column)
                    
                    var isWrited = false
                    
                    var writedLabel = 1
                    
                    if number == 1 {
                        
                        for (label, points) in self.objects {
                            
                            let inThisFigure = points.contains { self.isConnected(point: $0, with: currentPoint) }
                            if inThisFigure {
                                self.objects[label]?.append(currentPoint)
                                isWrited = true
                                writedLabel = label
                                break
                            }
                            
                        }
                        
                        if !isWrited {
                            self.objects[self.objects.count + 1] = [currentPoint]
                            writedLabel = self.objects.count
                        }
                        
                        
                    } else {
                        writedLabel = 0
                    }
                    
                    
                    self.labelsMatrix[row][column] = writedLabel
                    
//                    DispatchQueue.main.async {
//                        self.updateText(string: "\(writedLabel)")
//                    }
//                    Thread.sleep(forTimeInterval: 0.005)
                }
//                DispatchQueue.main.async {
//                    self.updateText(string: "\n")
//                }
            }
            
            self.isDrawingText = false
            
            self.mergeIntersectsFigures()
            
            print(pixelArray)
        }
    }
    
    private func calculateSquares() -> [Int: Int] {
        
        var squares = [Int: Int]()
        
        for row in 0..<self.labelsMatrix.count {
            for column in 0..<self.labelsMatrix[row].count {
                let item = self.labelsMatrix[row][column]
                squares[item] = (squares[item] ?? 0) + 1
            }
        }
        
        return squares
    }
    
    private func mergeIntersectsFigures() {
        
        DispatchQueue.global().async {
            
            var intersectPairs = [Int: Int]()
            
            for (label, points) in self.objects {
                for (otherLabel, otherPoints) in self.objects.prefix(self.objects.count - 1) {
                    var intersects = false
                    for point in points {
                        intersects = otherPoints.contains { self.isConnected(point: $0, with: point) }
                        if intersects {
                            if label != otherLabel && (!intersectPairs.keys.contains(label) && !intersectPairs.values.contains(label)) {
                                intersectPairs[label] = otherLabel
                            }
                            print("figure \(label) and \(otherLabel) are intersects")
                            break
                        }
                        
                    }
                    if intersects {
                        continue
                    }
                }
            }
            
            print("Pairs for merging: \(intersectPairs)")
            
            for pair in intersectPairs {
                if let pointsToRename = self.objects[pair.value] {
                    for poinToRename in pointsToRename {
                        self.labelsMatrix[Int(poinToRename.x)][Int(poinToRename.y)] = pair.key
                    }
                }
            }
            
            self.isDrawingText = true
            DispatchQueue.main.async {
                self.updateText(string: "\n")
            }
            
            Thread.sleep(forTimeInterval: 0.5)
            
            for row in 0..<self.labelsMatrix.count {
                for column in 0..<self.labelsMatrix[row].count {
                    let item = self.labelsMatrix[row][column]
                    DispatchQueue.main.async {
                        self.updateText(string: "\(item)")
                    }
                    Thread.sleep(forTimeInterval: 0.005)
                }
                DispatchQueue.main.async {
                    self.updateText(string: "\n")
                }
                
            }
            DispatchQueue.main.async {
                self.isDrawingText = false
                self.squareButton.isEnabled = true
            }
            
        }
    
    }
    
    private func isConnected(point: CGPoint, with: CGPoint) -> Bool {
        return (abs(point.x - with.x) <= 1) && (abs(point.y - with.y) <= 1)
    }

}


extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        print("Picked image: \(image)")
        DispatchQueue.main.async {
            self.imageView.image = image
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
    
}


extension MainViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = sectionInsets.left + sectionInsets.right
        let cellMargins = CGFloat(2 * self.labelsMatrix[0].count - 1)
        let additionalSpace: CGFloat = 2
        
        let availableSpace = self.collectionView.frame.width - (padding + cellMargins + additionalSpace)
        let widthPerItem = availableSpace / CGFloat(self.labelsMatrix[0].count)
        
        return CGSize(width: widthPerItem, height: widthPerItem)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.sectionInsets
    }
    
    /*
    Space between ROWS  [] [] []
                        /\
                         | - this
                        \/
                        [] [] []
    */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    /*                   this
      Space in ROW  [] []<--->[]
                    [] []     []
    */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.labelsMatrix.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PixelCell.identifier, for: indexPath) as! PixelCell
        if indexPath.item < 40 {
            cell.label.text = "\(self.labelsMatrix[0][indexPath.item])"
        } else {
            cell.label.text = "x"
        }
        
        return cell
    }
    
}
