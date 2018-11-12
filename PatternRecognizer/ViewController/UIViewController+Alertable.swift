//
//  UIViewController+Alertable.swift
//  PatternRecognizer
//
//  Created by Alexandr Nadtoka on 10/30/18.
//  Copyright © 2018 kreatimont. All rights reserved.
//

import UIKit

protocol Alertable {
    func showAlert(title: String?, message: String?, buttonTitle: String?, handler: ((UIAlertAction) -> ())?)
}

extension Alertable where Self: UIViewController {
    
    func showAlert(title: String?, message: String?, buttonTitle: String? = "OK", handler: ((UIAlertAction) -> ())? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: handler))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
}


