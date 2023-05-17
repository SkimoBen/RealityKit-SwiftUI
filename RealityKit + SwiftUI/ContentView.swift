//
//  ContentView.swift
//  RealityKit + SwiftUI
//
//  Created by Ben Pearman on 2023-03-19.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    //the reference to the image names. This gets them dynamically.
    private var models: [Model] = {
    
        let fileManager = FileManager.default
        //find the files otherwise return an empty array
        guard let path = Bundle.main.resourcePath, let
                files = try?
                fileManager.contentsOfDirectory(atPath: path)
        else {
            return []
        }
        
        //return the file names that have the suffix usdz
        var availableModels: [Model] = []
        for filename in files where
        filename.hasSuffix("usdz") {
            let modelName =
            filename.replacingOccurrences(of: ".usdz", with: "") //remove the suffix
            let model = Model(modelName: modelName)
            
            availableModels.append(model) //add the edited names to the array
        }
        return availableModels
    }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(modelConfirmedForPlacement: self.$modelConfirmedForPlacement) //camera view
            
            if self.isPlacementEnabled {
                PlacementButtonsView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models) //the $ gives the binding var write access. Only has read access without it.
            }
            
            
            
            
           
        }
    }
}

///VIEW: Creates the AR view for the scene. its a UIView representable because it uses UIKit.
struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    
    func makeUIView(context: Context) -> ARView {
        
        //CustomARView has the focusSquare
        let arView = CustomARView(frame: .zero)
        
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        //this gets the model object
        if let model = self.modelConfirmedForPlacement {
            
            //get the modelEntity hoping its not nil
            if let modelEntity = model.modelEntity {
                print("DEBUG: adding model to scene - \(model.modelName)")
                
                //create an anchor with any alignment, and attach the model to it.
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true)) //create a copy of the model. better for memory, and allows you to place multiple models.
                
                //add the anchor entity to the scene now that it has the model
                uiView.scene.addAnchor(anchorEntity)
            } else {
                print("Unable to load model entity for \(model.modelName)")
            }
            
            
            
            
            //this stops the error when running on devices. I think its because any UI updates must happen on the main thread.
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
        
    }
    
}

class CustomARView: ARView {
    //need the init for the foucs square
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        //using the FocusEntity package.
        let focusSquare = FocusEntity(on: self, focus: .classic)
        focusSquare.delegate = self
        focusSquare.setAutoUpdate(to: true)
        self.setupARView()
        
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupARView() {
        //this config uses ARKit to create the 3d environment.
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        //checks if the device can support scene reconstruction. Needs LiDAR.
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        //run the ar session using our configuration.
        self.session.run(config)
    }
}

extension CustomARView: FocusEntityDelegate {
    func toTrackingState() {
        print("tracking")
    }
    func toInitializingState() {
        print("initializing")
    }
}

///VIEW for the model slider
struct ModelPickerView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                //loop through the models array which is the photos.
                ForEach(0 ..< models.count, id: \.self) { index in
                    Button(action: {
                        print("DEBUG: selected model with name: \(self.models[index].modelName)")
                        
                        //if the user taps a thumbnail, the selected model gets set.
                        self.selectedModel = self.models[index]
                        
                        isPlacementEnabled = true
                    }) {
                        Image(uiImage: self.models[index].image) //get the image names
                            .resizable() //size the images
                            .frame(height: 80)
                            .aspectRatio(1/1, contentMode: .fit)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle()) //dont know if I need this.
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

///VIEW for the confirm and cancel buttons
struct PlacementButtonsView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    var body: some View {
        HStack {
            //cancel button
            Button(action: {
                print("DEBUG: model placement cancel")
                
                self.ResetPlacementParameters()
            }, label: {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(30)
                    .padding(20)
            })
            
            //confirm button
            Button(action: {
                print("DEBUG: model placement confirm")
                self.modelConfirmedForPlacement = self.selectedModel
               
                self.ResetPlacementParameters()
                
            }, label: {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(30)
                    .padding(20)
            })
        }
    }
    //function for removing the confirm / cancel buttons.
    func ResetPlacementParameters() {
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
