//
//  StoryboardExtension.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import Reusable

protocol StoryboardExtension: StoryboardBased {}

extension StoryboardExtension where Self: UIViewController {
    
    static func instantiate() -> Self {
        let identifier = String(describing: self)
        if let viewController = sceneStoryboard.instantiateViewController(withIdentifier: identifier) as? Self {
            return viewController
        }

        if let viewController = sceneStoryboard.instantiateInitialViewController() as? Self {
            return viewController
        }
        
        fatalError("The ViewController of '\(sceneStoryboard)' is not found")
    }
}

protocol FromMainStoryboard: StoryboardExtension {}

extension FromMainStoryboard where Self: UIViewController {
    static var sceneStoryboard: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
}
