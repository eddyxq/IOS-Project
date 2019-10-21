import UIKit
import RealityKit
import ARKit
import SceneKit

class ViewController: UIViewController
{
    @IBOutlet var arView: ARView!
    @IBOutlet var ARCanvas: ARSCNView!
    
    //runs once each time view is loaded
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //create maze
        setUpMaze()
        
        // Load the "Box" scene from the "Experience" Reality File
        //let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        //arView.scene.anchors.append(boxAnchor)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        let config = ARWorldTrackingConfiguration()
        ARCanvas.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        ARCanvas.session.pause()
    }
    
    //creates a box
    func setUpBox(size: Size, position: Position)
    {
        let box = SCNBox(width: CGFloat(size.width), height: CGFloat(size.height), length: CGFloat(size.length), chamferRadius: 0)
        
        //wall textures
        let imageMaterial1 = SCNMaterial()
        let wallImage1 = UIImage(named: "wall")
        imageMaterial1.diffuse.contents = wallImage1
        
        let imageMaterial2 = SCNMaterial()
        let wallImage2 = UIImage(named: "darkWall")
        imageMaterial2.diffuse.contents = wallImage2
        //apply skins
        box.materials = [imageMaterial2, imageMaterial2, imageMaterial2, imageMaterial2, imageMaterial1, imageMaterial2]
        //add box to scene
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(CGFloat(position.xCoord), CGFloat(position.yCoord), CGFloat(position.zCoord))
        ARCanvas.scene.rootNode.addChildNode(boxNode)
    }
    
    //create a maze
    func setUpMaze()
    {
        //dimensions of a box
        let WIDTH = 0.01
        let HEIGHT = 0.02
        let LENGTH = 0.01
        //init dimensions
        let dimensions = Size(width: WIDTH, height: HEIGHT, length: LENGTH)
            
        //position of first box
        var x = -0.1
        var y = -0.15
        var z = -0.03
        var c = 0.0
        //init position
        var location = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
        
        //hard coded maze
        let mazeMap = [
                        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1],
                        [1,0,0,0,0,0,1,1,0,0,0,1,0,0,1,3,0,1,0,1],
                        [1,0,1,1,1,0,6,1,0,1,0,0,0,1,1,1,0,1,0,1],
                        [1,0,0,0,1,1,1,1,0,1,1,0,1,1,0,1,0,1,0,1],
                        [1,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1],
                        [1,0,1,1,1,1,0,1,0,1,1,0,1,1,1,1,0,1,0,1],
                        [1,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,1],
                        [1,0,1,1,0,1,0,1,0,1,1,0,1,1,0,1,1,1,0,1],
                        [1,3,1,0,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,1],
                        [1,1,1,0,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1],
                        [1,0,1,0,1,0,0,1,0,1,0,0,0,1,0,1,0,1,0,1],
                        [1,0,0,0,0,0,1,1,0,0,0,1,1,1,0,1,0,0,0,1],
                        [1,0,1,1,1,0,1,0,0,1,0,0,0,1,3,1,1,1,0,1],
                        [1,0,0,0,1,1,1,1,0,1,1,1,0,1,1,1,0,0,0,1],
                        [1,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1],
                        [1,0,1,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,1,1],
                        [1,0,0,0,0,1,0,1,0,1,0,1,0,1,0,0,0,1,3,1],
                        [1,0,1,1,0,1,0,1,0,0,0,0,0,1,0,1,1,1,0,1],
                        [1,0,1,3,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,1],
                        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]]
        
        //maze size 20x20
        let NUMROW = 20
        let NUMCOL = 20
        
        for i in 0...NUMROW-1
        {
            for j in 0...NUMCOL-1
            {
                let row = mazeMap[i]
                let flag = row[j]
                
                if flag == 1
                {
                    location = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
                    setUpBox(size: dimensions, position: location)
                }
                x += 0.01
            }
            x -= 0.2
            z += 0.01
        }
    }
    
    //size of each box
    struct Size{
        var width = 0.0
        var height = 0.0
        var length = 0.0
    }
    
    //position of each box
    struct Position{
        var xCoord = 0.0
        var yCoord = 0.0
        var zCoord = 0.0
        var cRad = 0.0
    }
}