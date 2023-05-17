//
//  Model.swift
//  RealityKit + SwiftUI
//
//  Created by Ben Pearman on 2023-03-19.
//
//This file is for making the ARview async. Otherwie the view freezes when it loads the model

import UIKit
import RealityKit
import Combine


//This is
class Model {
    var modelName: String
    var image: UIImage
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        
        self.image = UIImage(named: modelName)!
        
        let filename = modelName + ".usdz"
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: {loadCompletion in
                //handle error
                print("DEBUG: Unable to load model entity for \(self.modelName)")
            }, receiveValue: {(modelEntity) in
                //get model entity
                self.modelEntity = modelEntity
                print("DEBUG: Successfully loaded model entity for \(modelName)")
            })
    }
}
