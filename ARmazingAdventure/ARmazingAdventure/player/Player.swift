import Foundation
import SceneKit
import ARKit

class Player
{
    let playerNode = SCNNode()
    var animations = [String: CAAnimation]()
    var name: String
    var health : Int
    var maxHP : Int
    var minAtkVal : Int
    var maxAtkVal : Int
    var level : Int
    var playerHP = 10
    var maxAP = 3
    var apCount = 3
    
    //constructor for initializing the player
    init(name: String, maxHP: Int, health: Int, minAtkVal: Int,maxAtkVal: Int, level: Int)
    {
        self.name = name
        self.health = health
        self.maxHP = maxHP
        self.minAtkVal = minAtkVal
        self.maxAtkVal = maxAtkVal
        self.level = level
    }
    
    // Player directions
    enum playerDirection: String
    {
        case up
        case down
        case left
        case right
        
        func direction() -> String
        {
            return self.rawValue
        }
    }
    
    // MARK: Animations & Models
    // creates a player character model with its animations
    func loadPlayerAnimations(_ sceneView: ARSCNView, _ position: ViewController.Position)
    {
        // Load the character in the idle animation
        let idleScene = SCNScene(named: "art.scnassets/characters/player/IdleFixed.dae")!
        // Add all the child nodes to the parent node
        for child in idleScene.rootNode.childNodes
        {
            playerNode.addChildNode(child)
        }
        
        playerNode.position = SCNVector3(CGFloat(position.xCoord), CGFloat(position.yCoord), CGFloat(position.zCoord))
        //size of the player model
        let playerModelSize = 0.00036
        playerNode.scale = SCNVector3(playerModelSize, playerModelSize, playerModelSize)
        // Rotating the character by 180 degrees
        playerNode.rotation = SCNVector4Make(0, 1, 0, .pi)
        
        playerNode.castsShadow = true
        playerNode.name = "player"
        sceneView.scene.rootNode.addChildNode(playerNode)
        //TODO: load more animations if available
        loadAnimation(withKey: "walk", sceneName: "art.scnassets/characters/player/WalkFixed", animationIdentifier: "WalkFixed-1")
        loadAnimation(withKey: "walkBack", sceneName: "art.scnassets/characters/player/WalkBackFixed", animationIdentifier: "WalkBackFixed-1")
        loadAnimation(withKey: "turnLeft", sceneName: "art.scnassets/characters/player/TurnLeftFixed", animationIdentifier: "TurnLeftFixed-1")
        loadAnimation(withKey: "turnRight", sceneName: "art.scnassets/characters/player/TurnRightFixed", animationIdentifier: "TurnRightFixed-1")
        loadAnimation(withKey: "lightAttack", sceneName: "art.scnassets/characters/player/LightAttackFixed", animationIdentifier: "LightAttackFixed-1")
        loadAnimation(withKey: "heavyAttack", sceneName: "art.scnassets/characters/player/HeavyAttackFixed", animationIdentifier: "HeavyAttackFixed-1")
        loadAnimation(withKey: "impact", sceneName: "art.scnassets/characters/player/PlayerImpactFixed", animationIdentifier: "PlayerImpactFixed-1")
        loadAnimation(withKey: "death", sceneName: "art.scnassets/characters/player/PlayerDeathFixed", animationIdentifier: "PlayerDeathFixed-1")
    }
    //load animations
    func loadAnimation(withKey: String, sceneName: String, animationIdentifier: String)
    {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self)
        {
            //The animation will only play once
            animationObject.repeatCount = 1
            //To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(0.5)
            animationObject.fadeOutDuration = CGFloat(0.5)
            
            //Store the animation for later use
            animations[withKey] = animationObject
        }
    }
    
    //play animation
    func playAnimation(_ sceneView: ARSCNView, key: String)
    {
        // Add the animation to start playing it right away
        sceneView.scene.rootNode.childNode(withName: "player", recursively: true)?.addAnimation(animations[key]!, forKey: key)
    }
    //stop animation
    func stopAnimation(_ sceneView: ARSCNView, key: String)
    {
        // Stop the animation with a smooth transition
        sceneView.scene.rootNode.childNode(withName: "player", recursively: true)?.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    // MARK: Player Movement Logics
    // The direction player is current facing.
    // Default: Up
    var currentPlayerDirection = playerDirection.up.direction()
    
    //turns the player 90 degrees counter clockwise
    func turnLeft(direction: String)
    {
        switch direction
        {
            case "up":
                currentPlayerDirection = playerDirection.left.direction()
            case "down":
                currentPlayerDirection = playerDirection.right.direction()
            case "left":
                currentPlayerDirection = playerDirection.down.direction()
            case "right":
                currentPlayerDirection = playerDirection.up.direction()
            default:
                break
        }
    }
    //turns the player 90 degrees clockwise
    func turnRight(direction: String)
    {
        switch direction
        {
            case "up":
                currentPlayerDirection = playerDirection.right.direction()
            case "down":
                currentPlayerDirection = playerDirection.left.direction()
            case "left":
                currentPlayerDirection = playerDirection.up.direction()
            case "right":
                currentPlayerDirection = playerDirection.down.direction()
            default:
                break
        }
    }
    
    //translates player
    func newMove(direction: String) -> SCNAction
    {
        let tileSize = CGFloat(0.04)
        var walkAction = SCNAction()
        switch direction
        {
            case "up":
                walkAction = SCNAction.moveBy(x: 0, y: 0, z: -tileSize, duration: 1.5)
            case "down":
                walkAction = SCNAction.moveBy(x: 0, y: 0, z: tileSize, duration: 1.5)
            case "left":
                walkAction = SCNAction.moveBy(x: -tileSize, y: 0, z: 0, duration: 1.5)
            case "right":
                walkAction = SCNAction.moveBy(x: tileSize, y: 0, z: 0, duration: 1.5)
            default:
                break
        }
        return walkAction
    }
    
    func spawnPlayer(_ sceneView: ARSCNView, _ position: ViewController.Position)
    {
        loadPlayerAnimations(sceneView, position)
    }
    
    // MARK: Getters & Setters
    func getPlayerNode() -> SCNNode
    {
        return playerNode
    }
    
    func getAPCount() -> String
    {
        return String(apCount)
    }
    
    func getHP() -> Int
    {
        return health
    }
    
    func getPlayerOrientation() -> String
    {
        return currentPlayerDirection
    }
    
    func getMaxAP() -> Int
    {
        return maxAP
    }
    
    func setHP(val: Int)
    {
        health = val
    }
    
    func setAP(val: Int)
    {
        apCount = val
    }
    
    func setPlayerOrientation(orientation: String)
    {
        switch orientation
        {
            case "up":
                currentPlayerDirection = playerDirection.right.direction()
            case "down":
                currentPlayerDirection = playerDirection.left.direction()
            case "left":
                currentPlayerDirection = playerDirection.up.direction()
            case "right":
                currentPlayerDirection = playerDirection.down.direction()
            default:
                break
        }
    }
    
    // MARK: Combat Functions
    
    //returns a integer in the range of attack power values
    func calcDmg() -> Int
    {
        return Int.random(in: minAtkVal ... maxAtkVal)
    }
    //sets size of hp bar in relation to hp
    func convertHPBar() -> CGFloat
    {
        return CGFloat(200 / maxHP)
    }
    //sets size of ap bar in relation to hp
    func convertAPBar() -> CGFloat
    {
        return CGFloat(200 / maxAP)
    }
    //consumes action point
    func useAP() -> CGFloat
    {
        apCount -= 1
        
        if apCount > 0
        {
            setAP(val: apCount)
        }
        let convertToAPBar = convertAPBar()
        
        return convertToAPBar
    }
}
