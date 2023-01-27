//
//  ViewController.swift
//  AR
//
//  Created by programming-xcode on 10/25/18.
//  Copyright © 2018 programming-xcode. All rights reserved.
//

import UIKit
import Foundation
import SceneKit
import SceneKit.ModelIO
import ARKit


@IBDesignable
class RoundedButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.blue
        layer.cornerRadius = 8
        clipsToBounds = true
        setTitleColor(.white, for: [])
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? UIColor.blue : UIColor.gray
        }
    }
    
    var toggledOn: Bool = true {
        didSet {
            if !isEnabled {
                backgroundColor = UIColor.gray
                return
            }
            backgroundColor = toggledOn ? UIColor.blue : UIColor.gray
        }
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var instructionView: UIVisualEffectView!
    @IBOutlet weak var toggleInstructionsButton: RoundedButton!
    
    let configuration = ARWorldTrackingConfiguration()
    
    // Audio player
    var player: AVAudioPlayer!
    
    var instructionsVisible: Bool = true {
        didSet {
            instructionView.isHidden = !instructionsVisible
            toggleInstructionsButton.toggledOn = instructionsVisible
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func toggleInstructionsButtonTapped(_ sender: Any) {
        guard !toggleInstructionsButton.isHidden && toggleInstructionsButton.isEnabled else { return }
        instructionsVisible.toggle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent auto-dimming of screen while using app
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Initialize buttons
        let resetButton = UIButton()
        let urlButton = UIButton()
        
        // Add reset button
        let rect1 = CGRect(x: 50, y: 50, width: 100, height: 50)
        resetButton.frame = rect1
        resetButton.setTitle("Reset", for: .normal)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        resetButton.isHidden = false
        
        sceneView.addSubview(resetButton)
        
        // Create external link buttons
        let rect2 = CGRect(x: 140, y: 50, width: 200, height: 50)
        urlButton.frame = rect2
        urlButton.setTitle("SE-8001 알아보기", for: .normal)
        urlButton.addTarget(self, action: #selector(openExternalLink), for: .touchUpInside)
        urlButton.isHidden = true
        
        sceneView.addSubview(urlButton)
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    @IBAction func reset(_ sender: UIButton!) {
        // Pause scene view
        sceneView.session.pause()
        
        // Remove button that redirects to link
        DispatchQueue.main.async {
            self.sceneView.subviews[1].isHidden = true
        }
        
        // Remove all child nodes
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        viewWillAppear(true)
    }
    
    @objc func openExternalLink(sender: UIButton!) {
        UIApplication.shared.open(URL(string: "https://www.kscedu.org/se-8001.main/")!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Models occluded by people are shown correctly
        if #available(iOS 13.0, *) {
            print("Segmentation with depth working!")
            ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth)
        } else {
            // Fallback on earlier versions
        }
        
        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "computer", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        configuration.detectionObjects = referenceObjects
        print(configuration.detectionObjects)

        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let objectAnchor = anchor as? ARObjectAnchor {
            // Print to console for debugging
            print("renderer called!")
            
            // Get world position of anchor object
            let translation = objectAnchor.transform.columns.3
            
            // Load .usdz object as SCNScene
            // let resourceName = objectAnchor.referenceObject.name!
            let resourceName = "SE_8001"
            let url = Bundle.main.url(forResource: resourceName, withExtension: "usdz")!
            let scene = try! SCNScene(url: url, options: [.checkConsistency: true])
        
            // Get rendered AR object via childNode
            let assetNode = scene.rootNode.childNode(withName: resourceName, recursively: true)!
            
            // Position rendered AR object above anchor
            assetNode.worldPosition = SCNVector3(x: translation.x, y: translation.y + 0.05, z: translation.z - 0.2)
            
            // Scale rendered AR object to fit into screen (can be adjusted)
            assetNode.scale = SCNVector3(x: 0.025, y: 0.025, z: 0.025)
        
            // Add lighting to scene so .usdz object texture is retained
            assetNode.light = SCNLight()
            assetNode.light?.type = .directional
            
            // Play music
            let arMusic = SCNAudioSource.init(named: "music.wav")!
            arMusic.volume = 1.0
            arMusic.isPositional = false
            arMusic.load()
            
            assetNode.runAction(SCNAction.playAudio(arMusic, waitForCompletion: true))
            
            sceneView.scene.rootNode.addChildNode(assetNode)
            
            // Show urlButton (works, but currently ad-hoc)
            DispatchQueue.main.async {
                self.sceneView.subviews[1].isHidden = false
            }
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
