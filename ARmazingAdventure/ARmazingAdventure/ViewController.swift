import UIKit
import RealityKit
import ARKit
import SceneKit
import SpriteKit

class ViewController: UIViewController
{
    //set up game states
    enum GameState: String
    {
        case playerTurn
        case enemyTurn
        
        func state() -> String
        {
            return self.rawValue
        }
    }
    //setting scene to AR
    var config = ARWorldTrackingConfiguration()
    
    //size of each box
    struct Size
    {
        var width = 0.0
        var height = 0.0
        var length = 0.0
    }
    
    //position of each box
    struct Position
    {
        var xCoord = 0.0
        var yCoord = 0.0
        var zCoord = 0.0
        var cRad = 0.0
    }
    
    @IBOutlet var arView: ARView!
    @IBOutlet var ARCanvas: ARSCNView!
    @IBOutlet weak var HelpImage: UIImageView!
    @IBOutlet weak var BackButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var turnIndicator: UILabel!
    @IBOutlet weak var enemyHPBarLabel: UILabel!
    @IBOutlet var backView: UIView!
    
    @IBOutlet var blackView: UIView!
    
    var animations = [String: CAAnimation]()
    var idle: Bool = true
    var mazeWallNode = SCNNode()
    var mazeFloorNode = SCNNode()
    var location = Position(xCoord: 0.0, yCoord: 0.0, zCoord: 0.0, cRad: 0.0)
    
    var currentGameState = GameState.playerTurn.state()
    
    var player = Player(name: "Player 1", maxHP: 10, health: 10, minAtkVal: 1, maxAtkVal: 3, level: 1)
    var minionPool = [Minion]()
    var targetMinion = Minion()
    var bossPool = [Boss]()
    
    var enemyHPBorder = SKSpriteNode()
    var enemyHPBar = SKSpriteNode(color: #colorLiteral(red: 0.4709299803, green: 0, blue: 0.04640627652, alpha: 1), size: CGSize(width: 200, height: 20))
    var playerHPBorder = SKSpriteNode()
    var playerHPBar = SKSpriteNode(color: #colorLiteral(red: 0.4709299803, green: 0, blue: 0.04640627652, alpha: 1), size: CGSize(width: 200, height: 40))
    var playerAPBorder = SKSpriteNode()
    var playerAPBar = SKSpriteNode(color: #colorLiteral(red: 0.4136915207, green: 0.2687294185, blue: 0.04161217064, alpha: 1) , size: CGSize(width: 200, height: 20))
    
    //true when user has placed the maze on surface
    var mazePlaced = false
    var planeFound = false
    
    //identifying value in array
    let FLOOR = 0
    let WALL = 1
    let PLAYER = 2
    let BOSS = 3
    let MINION = 4
    let FINISHPOINT = 9
    //creates a new random maze stage that is tracked in a 2d array
    var maze = Maze().newStage()
    //the dimensions of the maze
    let NUMROW = Maze().getHeight()
    let NUMCOL = Maze().getWidth()
    
    // MARK: ViewController Functions
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //setting scene to AR
        config = ARWorldTrackingConfiguration()
        //search for horizontal planes
        config.planeDetection = .horizontal
        //apply configurations
        ARCanvas.session.run(config)
        //display the detected plane
        ARCanvas.delegate = self
        ARCanvas.autoenablesDefaultLighting = false
        //shows the feature points
        ARCanvas.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        ARCanvas.scene.rootNode.castsShadow = true
        //setup the in game inerface
        setupOverlay()
        //enable music
        setupDungeonMusic()
        //turn on lighting and fog
        setupARLight()
        setupFog()
        toggleHelp(mode: "off")
        //enables user to tap detected plane for maze placement
        addTapGestureToSceneView()
        //adds arrow pad to screen
        createGamepad()
        
        turnIndicator.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    // MARK: HUD Overlay
    //creates the ingame HUD
    func setupOverlay()
    {
        let hud = SKScene()
        hud.scaleMode = .resizeFill
        let centerX = view.bounds.midX
        let topY = view.bounds.maxY
        
        //Enemy HP Bar & Borders
        let hpBorderImage = UIImage(named: "minionHPBorder")
        let hpBorderTexture = SKTexture(image: hpBorderImage!)
        enemyHPBorder = SKSpriteNode(texture: hpBorderTexture)
        enemyHPBorder.position = CGPoint(x: centerX, y: topY-40)
        enemyHPBar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        enemyHPBar.position = CGPoint(x: (centerX)-100, y: topY-40)
        // Player HP Bar & Borders
        let playerHpBorderImage = UIImage(named: "playerHPBorder")
        let playerHpBorderTexture = SKTexture(image: playerHpBorderImage!)
        playerHPBorder = SKSpriteNode(texture: playerHpBorderTexture)
        playerHPBorder.position = CGPoint(x: centerX, y: 100)
        playerHPBar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        playerHPBar.position = CGPoint(x: centerX-100, y: 100)
        // Player AP Bar & Borders
        let playerApBorderImage = UIImage(named: "playerAPBorder")
        let playerApBorderTexture = SKTexture(image: playerApBorderImage!)
        playerAPBorder = SKSpriteNode(texture: playerApBorderTexture)
        playerAPBorder.position = CGPoint(x: centerX, y: 50)
        playerAPBar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        playerAPBar.position = CGPoint(x: centerX-100, y: 50)
        
        hud.addChild(playerAPBar)
        hud.addChild(playerAPBorder)
        hud.addChild(playerHPBar)
        hud.addChild(playerHPBorder)
        hud.addChild(enemyHPBar)
        hud.addChild(enemyHPBorder)
        ARCanvas.overlaySKScene = hud
        
        toggleEnemyLabels(mode: "Off")
    }
    
    //toggle for turning the ingame help menu on and off
    func toggleHelp(mode: String)
    {
        if mode == "on"
        {
            BackButton.isHidden = false
            HelpImage.isHidden = false
            backView.isHidden = false
            blackView.isHidden = false
            ARCanvas.overlaySKScene!.isHidden = true
        }
        else
        {
            HelpImage.isHidden = true
            BackButton.isHidden = true
            backView.isHidden = true
            blackView.isHidden = true
            ARCanvas.overlaySKScene!.isHidden = false
        }
    }
    
    //toggle for turning the ingame help menu on and off
    func toggleEnemyLabels(mode: String)
    {
        if mode == "On"
        {
            enemyHPBarLabel.isHidden = false
            enemyHPBar.isHidden = false
            enemyHPBorder.isHidden = false
        }
        else
        {
            enemyHPBarLabel.isHidden = true
            enemyHPBar.isHidden = true
            enemyHPBorder.isHidden = true
        }
    }
    
    // MARK: Game State Management
    //resizes the bar to reflect the current AP value
    func updateAP()
    {
        var action = SKAction()
        let newBarWidth = playerAPBar.size.width - player.useAP()
        
        if newBarWidth <= 0
        {
            action = SKAction.resize(toWidth: 0.0, duration: 0.25)
        }
        else
        {
            action = SKAction.resize(toWidth: CGFloat(newBarWidth), duration: 0.25)
        }
        playerAPBar.run(action)
        
        if player.apCount == 0
        {
            stateChange()
        }
    }
    
    // updates the turn indicator
    func updateIndicator()
    {
        if currentGameState == "playerTurn"
        {
            turnIndicator.text = "Your Turn"
            turnIndicator.textColor = UIColor.green
        }
        else if currentGameState == "enemyTurn"
        {
            turnIndicator.text = "Enemy Turn"
            turnIndicator.textColor = UIColor.red
        }
        turnIndicator.isHidden = false
        turnIndicator.shadowColor = UIColor.black
    }
    
    // changes the game state
    func stateChange()
    {
        if currentGameState == "playerTurn"
        {
            currentGameState = GameState.enemyTurn.state()
            //enemyMove()
            enemyAction()
        }
        else if currentGameState == "enemyTurn"
        {
            currentGameState = GameState.playerTurn.state()
            //refills the player's AP bar to full
            player.setAP(val: player.getMaxAP())
            let action = SKAction.resize(toWidth: CGFloat(200), duration: 0.25)
            playerAPBar.run(action)
        }
        //updateIndicator()
    }
    // MARK: Enemy Turn Logics
    //called on enemies turn allow them to attack the player
    func enemyAction()
    {
        if enemyInRange(row: Maze().getRow(maze: maze), col: Maze().getCol(maze: maze))
        {
            var action = SKAction()
            let newBarWidth = playerHPBar.size.width - targetMinion.attackPlayer(target: player)
            //if enemy is dead
            if newBarWidth <= 0
            {
                action = SKAction.resize(toWidth: 0.0, duration: 0.25)
            }
            else
            {
                action = SKAction.resize(toWidth: CGFloat(newBarWidth), duration: 0.25)
            }
            targetMinion.playAnimation(ARCanvas, key: "attack")
            player.playAnimation(ARCanvas, key: "impact")
            playerHPBar.run(action)
        }
        stateChange()
        
        //logic for when player dies
        if player.getHP() < 1
        {
            //Doesn't let user move or do anything when dead
            view.isUserInteractionEnabled = false
            let audio = SCNAudioSource(named: "art.scnassets/audios/Laugh.wav")
            let audioAction = SCNAction.playAudio(audio!, waitForCompletion: true)
            player.getPlayerNode().runAction(audioAction)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                        self.restart()
                    }
        }
    }
    
    // MARK: Add maze on tap
    @objc func addMazeToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer)
    {
        //adds maze only if it has not been placed and a plane is found
        if mazePlaced == false && planeFound
        {
            //disable plane detection by resetting configurations
            let configuration = ARWorldTrackingConfiguration()
            ARCanvas.session.run(configuration)
            
            //get coordinates of where user tapped
            let tapLocation = recognizer.location(in: ARCanvas)
            let hitTestResults = ARCanvas.hitTest(tapLocation, types: .existingPlaneUsingExtent)

            //if tapped on plane, translate tapped location to plane coordinates
            guard let hitTestResult = hitTestResults.first else { return }
            let translation = hitTestResult.worldTransform.translation
            let x = Double(translation.x)
            let y = Double(translation.y)
            let z = Double(translation.z)
            
            //spawn maze on location
            location = Position(xCoord: x, yCoord: y, zCoord: z, cRad: 0.0)
            setUpMaze(position: location)
            
            //flip flag to true so you cannot spawn multiple mazes
            mazePlaced = true
            //updateIndicator()
            //disable plane detection by resetting configurations
            config.planeDetection = []
            self.ARCanvas.session.run(config)
            
            //hide plane and feature points
            self.ARCanvas.debugOptions = []
        }
    }
    
    //accepts tap input for placing maze
    func addTapGestureToSceneView()
    {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addMazeToSceneView(withGestureRecognizer:)))
        ARCanvas.addGestureRecognizer(tapGestureRecognizer)
    }

    // MARK: Buttons & Controlls
    //creates 4 buttons
    func createGamepad()
    {

        //right arrow
        let rightButton = UIButton(type: .system)
        let rightArrow = UIImage(named: "rightArrow")
        rightButton.setImage(rightArrow, for: .normal)
        rightButton.addTarget(self, action: #selector(rightButtonClicked), for: .touchUpInside)
        self.view.addSubview(rightButton)

        //left arrow
        let leftButton = UIButton(type: .system)
        let leftArrow = UIImage(named: "leftArrow")
        leftButton.setImage(leftArrow, for: .normal)
        leftButton.addTarget(self, action: #selector(leftButtonClicked), for: .touchUpInside)
        self.view.addSubview(leftButton)

        //up arrow
        let upButton = UIButton(type: .system)
        let upArrow = UIImage(named: "upArrow")
        upButton.setImage(upArrow, for: .normal)
        upButton.addTarget(self, action: #selector(upButtonClicked), for: .touchUpInside)
        self.view.addSubview(upButton)

        //down arrow
        let downButton = UIButton(type: .system)
        let downArrow = UIImage(named: "downArrow")
        downButton.setImage(downArrow, for: .normal)
        downButton.addTarget(self, action: #selector(downButtonClicked), for: .touchUpInside)
        self.view.addSubview(downButton)
        
        //light attack
        let lightAttackButton = UIButton(type: .system)
        let attack1 = UIImage(named: "LightAttack")
        lightAttackButton.setImage(attack1, for: .normal)
        lightAttackButton.addTarget(self, action: #selector(lightAttackButtonClicked), for: .touchUpInside)
        self.view.addSubview(lightAttackButton)
        
        //heavy attack
        let heavyAttackButton = UIButton(type: .system)
        let attack2 = UIImage(named: "HeavyAttack")
        heavyAttackButton.setImage(attack2, for: .normal)
        heavyAttackButton.addTarget(self, action: #selector(heavyAttackButtonClicked), for: .touchUpInside)
        self.view.addSubview(heavyAttackButton)
        
        //end turn
        let endTurnButton = UIButton(type: .system)
        let endButton = UIImage(named: "SkipTurn")
        endTurnButton.setImage(endButton, for: .normal)
        endTurnButton.addTarget(self, action: #selector(endTurnButtonClicked), for: .touchUpInside)
        self.view.addSubview(endTurnButton)
        endTurnButton.isHidden = true
        
        let movementRing = UIButton(type: .system)
        movementRing.setImage(#imageLiteral(resourceName: "movementButtonRing"), for: .normal)
        movementRing.isUserInteractionEnabled = false
        self.view.addSubview(movementRing)
        
        //constraints
        for button in [rightButton, upButton, downButton, leftButton, rightButton, heavyAttackButton, lightAttackButton, endTurnButton, movementRing]
        {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1).isActive = true
            button.tintColor = .lightGray
        }

        rightButton.bottomAnchor.constraint(equalTo: downButton.topAnchor).isActive = true
        rightButton.leftAnchor.constraint(equalTo: downButton.rightAnchor).isActive = true
        
        leftButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 24).isActive = true
        leftButton.bottomAnchor.constraint(equalTo: downButton.topAnchor).isActive = true

        upButton.bottomAnchor.constraint(equalTo: leftButton.topAnchor).isActive = true
        upButton.leftAnchor.constraint(equalTo: leftButton.rightAnchor).isActive = true

        downButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24).isActive = true
        downButton.leftAnchor.constraint(equalTo: leftButton.rightAnchor).isActive = true

        lightAttackButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        lightAttackButton.rightAnchor.constraint(equalTo: heavyAttackButton.leftAnchor, constant: -24).isActive = true
        lightAttackButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -64).isActive = true

        heavyAttackButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        heavyAttackButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -24).isActive = true
        heavyAttackButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -64).isActive = true

        endTurnButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        endTurnButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 24).isActive = true
        endTurnButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64).isActive = true
        
        movementRing.widthAnchor.constraint(equalToConstant: 165).isActive = true
        movementRing.centerYAnchor.constraint(equalTo: leftButton.centerYAnchor).isActive = true
        movementRing.centerXAnchor.constraint(equalTo: downButton.centerXAnchor).isActive = true
        
        view.bringSubviewToFront(blackView)
        view.bringSubviewToFront(HelpImage) // Keep help above gamepad
        view.bringSubviewToFront(backView)
        view.bringSubviewToFront(BackButton)
    }
    // MARK: Arrow Button Logics
    func canMove(direction: String) -> Bool
    {
        return
            //ensures game is setup in AR
            (mazePlaced
            //allows movement only when player has available action points
            && player.apCount > 0
            //ensures movement only happens during player phase
            && currentGameState == "playerTurn"
            //checks for obstacles and collisions
            && move(direction: direction) ? true : false)
    }
    
    //right button logic
    @objc func rightButtonClicked(sender : UIButton)
    {
        if mazePlaced && currentGameState != "enemyTurn"
        {
            //sender.preventRepeatedPresses()
            
            if player.currentPlayerDirection == "up"
            {
                player.turnRight(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "down"
            {
                player.turnLeft(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: -(.pi/2), z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnLeft")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "left"
            {
                player.turnLeft(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: -(.pi/2), z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnLeft")
                player.getPlayerNode().runAction(turnAction)
                player.turnLeft(direction: player.currentPlayerDirection)
                player.playAnimation(ARCanvas, key: "turnLeft")
                player.getPlayerNode().runAction(turnAction)
            }
            
            if canMove(direction: "right")
            {
                player.playAnimation(ARCanvas, key: "walk")
                player.getPlayerNode().runAction(player.newMove(direction: "right"))
                updateAP()
            }
            
            //check if minion is nearby
            if enemyInRange(row: Maze().getRow(maze: maze), col: Maze().getCol(maze: maze))
            {
                //display hit points bar
                toggleEnemyLabels(mode: "On")
                //update hp labels
                enemyHPBarLabel.text = String(targetMinion.getName()) + ": " + String(targetMinion.getHP()) + " / " + String(targetMinion.getMaxHP())
            }
            else
            {
                toggleEnemyLabels(mode: "Off")
            }
            enemyHPBar.size.width = CGFloat(targetMinion.getHP()) / CGFloat(targetMinion.getMaxHP()) * 200
        }
    }
    //left button logic
    @objc func leftButtonClicked(sender : UIButton)
    {
        if mazePlaced && currentGameState != "enemyTurn"
        {
            //sender.preventRepeatedPresses()
            
            if player.currentPlayerDirection == "up"
            {
                player.turnLeft(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: -(.pi/2), z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnLeft")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "down"
            {
                player.turnRight(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "right"
            {
                player.turnRight(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
                player.turnRight(direction: player.currentPlayerDirection)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
            }
            
            if canMove(direction: "left")
            {
                player.playAnimation(ARCanvas, key: "walk")
                player.getPlayerNode().runAction(player.newMove(direction: "left"))
                updateAP()
            }
            
            //check if minion is nearby
            if enemyInRange(row: Maze().getRow(maze: maze), col: Maze().getCol(maze: maze))
            {
                //display hit points bar
                toggleEnemyLabels(mode: "On")
                //update hp labels
                enemyHPBarLabel.text = String(targetMinion.getName()) + ": " + String(targetMinion.getHP()) + " / " + String(targetMinion.getMaxHP())
            }
            else
            {
                toggleEnemyLabels(mode: "Off")
            }
            enemyHPBar.size.width = CGFloat(targetMinion.getHP()) / CGFloat(targetMinion.getMaxHP()) * 200
        }
    }
    //up button logic
    @objc func upButtonClicked(sender : UIButton)
    {
        if mazePlaced && currentGameState != "enemyTurn"
        {
            //sender.preventRepeatedPresses()
            
            if player.currentPlayerDirection == "down"
            {
                player.turnRight(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
                player.turnRight(direction: player.currentPlayerDirection)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "left"
            {
                player.turnRight(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "right"
            {
                player.turnLeft(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: -(.pi/2), z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnLeft")
                player.getPlayerNode().runAction(turnAction)
            }
            
            if canMove(direction: "forward")
            {
                player.playAnimation(ARCanvas, key: "walk")
                player.getPlayerNode().runAction(player.newMove(direction: "up"))
                updateAP()
            }
            
            //check if minion is nearby
            if enemyInRange(row: Maze().getRow(maze: maze), col: Maze().getCol(maze: maze))
            {
                //display hit points bar
                toggleEnemyLabels(mode: "On")
                //update hp labels
                enemyHPBarLabel.text = String(targetMinion.getName()) + ": " + String(targetMinion.getHP()) + " / " + String(targetMinion.getMaxHP())
            }
            else
            {
                toggleEnemyLabels(mode: "Off")
            }
            enemyHPBar.size.width = CGFloat(targetMinion.getHP()) / CGFloat(targetMinion.getMaxHP()) * 200
        }
    }
    //down button logic
    @objc func downButtonClicked(sender : UIButton)
    {
        if mazePlaced && currentGameState != "enemyTurn"
        {
            //sender.preventRepeatedPresses()
            
            if player.currentPlayerDirection == "up"
            {
               player.turnRight(direction: player.currentPlayerDirection)
               let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
               player.playAnimation(ARCanvas, key: "turnRight")
               player.getPlayerNode().runAction(turnAction)
               player.turnRight(direction: player.currentPlayerDirection)
               player.playAnimation(ARCanvas, key: "turnRight")
               player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "left"
            {
                player.turnLeft(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: -(.pi/2), z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnLeft")
                player.getPlayerNode().runAction(turnAction)
            }
            else if player.currentPlayerDirection == "right"
            {
                player.turnRight(direction: player.currentPlayerDirection)
                let turnAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
                player.playAnimation(ARCanvas, key: "turnRight")
                player.getPlayerNode().runAction(turnAction)
            }
            
            if canMove(direction: "backward")
            {
                player.playAnimation(ARCanvas, key: "walkBack")
                player.getPlayerNode().runAction(player.newMove(direction: "down"))
                updateAP()
            }
            
           //check if minion is nearby
           if enemyInRange(row: Maze().getRow(maze: maze), col: Maze().getCol(maze: maze))
           {
                //display hit points bar
                toggleEnemyLabels(mode: "On")
                //update hp labels
                enemyHPBarLabel.text = String(targetMinion.getName()) + ": " + String(targetMinion.getHP()) + " / " + String(targetMinion.getMaxHP())
           }
           else
           {
                toggleEnemyLabels(mode: "Off")
           }
            enemyHPBar.size.width = CGFloat(targetMinion.getHP()) / CGFloat(targetMinion.getMaxHP()) * 200
        }
    }
    // MARK: Help Button Logic
    @IBAction func helpButtonPressed(_ sender: Any)
    {
        toggleHelp(mode: "on")
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any)
    {
        toggleHelp(mode: "off")
    }
    
    // MARK: Attack Buttons
    //light attack button logic
    @objc func lightAttackButtonClicked(sender : UIButton)
    {
        if mazePlaced && currentGameState != "enemyTurn"
        {
            sender.preventRepeatedPresses()
            attack(type: "light")
        }
    }
    
    //heavy attack button logic
    @objc func heavyAttackButtonClicked(sender : UIButton)
    {
        if mazePlaced && currentGameState != "enemyTurn"
        {
            sender.preventRepeatedPresses()
            attack(type: "heavy")
        }
    }
    //end turn button logic
    @objc func endTurnButtonClicked(sender : UIButton)
    {
        if (mazePlaced)
        {
            sender.preventRepeatedPresses()
            stateChange()
        }
    }
    
    
    func enemyMove()
    {
        let results = Solver(maze: maze).moveRandomMinion()
        maze = results.0
        let directionMoved = results.1
        let origin = results.2
        
        var targetMinion = findMinionByLocation(location: (row: origin.0, col: origin.1))
        
        if origin != (0,0)
        {
            if directionMoved == "up"
            {
                turnFace(direction: "north", targetMinion: &targetMinion)
                targetMinion.getMinionNode().runAction(player.newMove(direction: "up"))
                targetMinion.setLocation(location: (row: origin.0-1, col: origin.1))
            }
            else if directionMoved == "down"
            {
                turnFace(direction: "south", targetMinion: &targetMinion)
                targetMinion.getMinionNode().runAction(player.newMove(direction: "down"))
                targetMinion.setLocation(location: (row: origin.0+1, col: origin.1))
            }
            else if directionMoved == "left"
            {
                turnFace(direction: "west", targetMinion: &targetMinion)
                targetMinion.getMinionNode().runAction(player.newMove(direction: "left"))
                targetMinion.setLocation(location: (row: origin.0, col: origin.1-1))
            }
            else if directionMoved == "right"
            {
                turnFace(direction: "east", targetMinion: &targetMinion)
                targetMinion.getMinionNode().runAction(player.newMove(direction: "right"))
                targetMinion.setLocation(location: (row: origin.0, col: origin.1+1))
            }
        }
    }
    
    func attack(type: String)
    {
        if type == "light"
        {
            //play animation
            player.playAnimation(ARCanvas, key: "lightAttack")
            let audio = SCNAudioSource(named: "art.scnassets/audios/lightAttack.wav")
            let audioAction = SCNAction.playAudio(audio!, waitForCompletion: true)
            player.getPlayerNode().runAction(audioAction)
        }
        else if type == "heavy"
        {
            //play animation
            player.playAnimation(ARCanvas, key: "heavyAttack")
            let audio = SCNAudioSource(named: "art.scnassets/audios/heavyAttack.wav")
            let audioAction = SCNAction.playAudio(audio!, waitForCompletion: true)
            player.getPlayerNode().runAction(audioAction)
        }
        
        //deal damage to enemy
        if enemyInRange(row: Maze().getRow(maze: maze), col: Maze().getCol(maze: maze))
        {
            var action = SKAction()
            enemyHPBar.size.width = 200
            
            targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
            //light attacks do standard damage
            if type == "light"
            {
                targetMinion.setHP(val: targetMinion.getHP()-player.calcDmg())
                targetMinion.playAnimation(ARCanvas, key: "impact")
                
            }
            //heavy attacks do double damage
            else if type == "heavy"
            {
                targetMinion.setHP(val: targetMinion.getHP()-player.calcDmg())
                targetMinion.playAnimation(ARCanvas, key: "impact")
            }

            //consume AP
            updateAP()
            
            //update hp bar
            enemyHPBar.size.width = CGFloat(targetMinion.getHP()) / CGFloat(targetMinion.getMaxHP()) * 200
            action = SKAction.resize(toWidth: CGFloat(enemyHPBar.size.width), duration: 0.25)
            
            //update hp label
            enemyHPBarLabel.text = String(targetMinion.getName()) + ": " + String(targetMinion.getHP()) + " / " + String(targetMinion.getMaxHP())
            enemyHPBar.run(action)
            
            //check if enemy is dead
            if targetMinion.isDead()
            {
                targetMinion.getMinionNode().removeFromParentNode()
                //remove enemy data from maze
                maze[adjacentEnemyLocation.0][adjacentEnemyLocation.1] = 0
                //remove from minion pool
                var removalIndex = -1
                for i in 0 ..< minionPool.count
                {
                    if minionPool[i].arrayLocation.0 == adjacentEnemyLocation.0 && minionPool[i].arrayLocation.1 == adjacentEnemyLocation.1
                    {
                        removalIndex = i
                    }
                }
                if removalIndex > -1
                {
                    minionPool.remove(at: removalIndex)
                }
                //hide hp bars
                toggleEnemyLabels(mode: "Off")
            }
        }
    }
    // MARK: Player Movement
        
    //moves and updates player location
    func move(direction: String) -> Bool
    {
        var canMove = false
        var playerRow = Maze().getRow(maze: maze)
        var playerCol = Maze().getCol(maze: maze)
        // remove player from current position
        maze[playerRow][playerCol] = FLOOR
        switch (direction)
        {
            case "backward":
                playerRow += 1
            case "forward":
                playerRow -= 1
            case "left":
                playerCol -= 1
            case "right":
                playerCol += 1
            default:
                break
        }
        if maze[playerRow][playerCol] == FLOOR
        {
            maze[playerRow][playerCol] = PLAYER
            canMove = true
        }
        else if maze[playerRow][playerCol] == FINISHPOINT
        {
            view.isUserInteractionEnabled = false
            let audio = SCNAudioSource(named: "art.scnassets/audios/TaDa.wav")
            let audioAction = SCNAction.playAudio(audio!, waitForCompletion: true)
            player.getPlayerNode().runAction(audioAction)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.restart()
            }
        }
        else // player does not move, returns to origin and turns facing the direction he tried to move in
        {
            switch (direction)
            {
                case "backward":
                    playerRow -= 1
                case "forward":
                    playerRow += 1
                case "left":
                    playerCol += 1
                case "right":
                    playerCol -= 1
                default:
                    break
            }
            maze[playerRow][playerCol] = PLAYER;
        }
        return canMove
    }
    
    func turnFace(direction: String, targetMinion: inout Minion)
    {
        
        if direction == "north"
        {
            if targetMinion.currentMinionDirection == "down"
            {
                targetMinion.turn180(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "left"
            {
                targetMinion.turnRight(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "right"
            {
                targetMinion.turnLeft(direction: targetMinion.currentMinionDirection)
            }
        }
        else if direction == "south"
        {
            if targetMinion.currentMinionDirection == "up"
            {
                targetMinion.turn180(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "left"
            {
                targetMinion.turnLeft(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "right"
            {
                targetMinion.turnRight(direction: targetMinion.currentMinionDirection)
            }
        }
        else if direction == "west"
        {
            if targetMinion.currentMinionDirection == "up"
            {
                targetMinion.turnLeft(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "down"
            {
                targetMinion.turnRight(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "right"
            {
                targetMinion.turn180(direction: targetMinion.currentMinionDirection)
            }
        }
        else if direction == "east"
        {
            if targetMinion.currentMinionDirection == "up"
            {
                targetMinion.turnRight(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "down"
            {
                targetMinion.turnLeft(direction: targetMinion.currentMinionDirection)
            }
            else if targetMinion.currentMinionDirection == "left"
            {
                targetMinion.turn180(direction: targetMinion.currentMinionDirection)
            }
        }
    }
    
    var adjacentEnemyLocation = (9999,9999)
    func enemyInRange(row: Int, col: Int) -> Bool
    {
        var surroundingEnemyCount = 0
        
        var minionInRange = false
        //check south of player
        if (row < NUMROW-1)
        {
            if maze[row+1][col] == MINION
            {
                adjacentEnemyLocation = (row+1, col)
                minionInRange = true
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
                turnFace(direction: "north", targetMinion: &targetMinion)
            }
            surroundingEnemyCount += 1
        }
        //check east of player
        if (col < NUMCOL-1)
        {
            if maze[row][col+1] == MINION
            {
                adjacentEnemyLocation = (row, col+1)
                minionInRange = true
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
                turnFace(direction: "west", targetMinion: &targetMinion)
            }
            surroundingEnemyCount += 1
        }
        //check west of player
        if (row > 0)
        {
            if maze[row][col-1] == MINION
            {
                adjacentEnemyLocation = (row, col-1)
                minionInRange = true
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
                turnFace(direction: "east", targetMinion: &targetMinion)
            }
            surroundingEnemyCount += 1
        }
        //check north of player
        if (col > 0)
        {
            if maze[row-1][col] == MINION
            {
                adjacentEnemyLocation = (row-1, col)
                minionInRange = true
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
                turnFace(direction: "south", targetMinion: &targetMinion)
            }
            surroundingEnemyCount += 1
        }
        if minionInRange
        {
            targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
        }
        
        //if the player is surrounded by multiple enemies then return the one they are facing
        if surroundingEnemyCount > 1
        {
            if player.getPlayerOrientation() == "up"
            {
                adjacentEnemyLocation = (row-1, col)
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
            }
            
            else if player.getPlayerOrientation() == "down"
            {
                adjacentEnemyLocation = (row+1, col)
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
            }
            
            else if player.getPlayerOrientation() == "left"
            {
                adjacentEnemyLocation = (row, col-1)
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
            }
            
            else if player.getPlayerOrientation() == "right"
            {
                adjacentEnemyLocation = (row, col+1)
                targetMinion = findMinionByLocation(location: (row: adjacentEnemyLocation.0, col: adjacentEnemyLocation.1))
            }
        }
        return minionInRange
    }
    
    // MARK: Combat
    //returns the instance of the minion at a specific index
    func findMinionByLocation(location: (row: Int, col: Int)) -> Minion
    {
        for minion in minionPool
        {
            if minion.arrayLocation == location
            {
                return minion
            }
        }
        //code shouldn't reach here, all minions should be in list
        return minionPool[0]
    }
    // MARK: Music
    //plays background music
    func setupDungeonMusic()
    {
        let audio = SCNAudioSource(named: "art.scnassets/audios/dungeonMusic.wav")
        audio?.volume = 0.65
        audio?.loops = true
        let audioAction = SCNAction.playAudio(audio!, waitForCompletion: true)
        player.getPlayerNode().runAction(audioAction)
    }
    //MARK: Lighting & Fog
    //creates tunnel vision
    func setupARLight()
    {
        let charLight = SCNLight()
        charLight.type = .spot
        charLight.spotOuterAngle = CGFloat(25)
        charLight.zFar = CGFloat(100)
        charLight.zNear = CGFloat(0.01)
        charLight.castsShadow = true
        charLight.intensity = CGFloat(2000)
        ARCanvas.pointOfView?.light = charLight
    }
    //adds fog to the scene
    func setupFog()
    {
        ARCanvas.scene.fogColor = UIColor.darkGray
        ARCanvas.scene.fogStartDistance = CGFloat(0.0)
        ARCanvas.scene.fogEndDistance = CGFloat(3.0)
    }
    //MARK: Maze Map Setup
    //creates the maze wall
    func setupWall(size: Size, position: Position)
    {
        let wall = SCNBox(width: CGFloat(size.width), height: CGFloat(size.height), length: CGFloat(size.length), chamferRadius: 0)
        
        //wall textures
        let imageMaterial1 = SCNMaterial()
        let wallImage1 = UIImage(named: "wall")
        imageMaterial1.diffuse.contents = wallImage1
        
        //apply skins
        wall.materials = [imageMaterial1, imageMaterial1, imageMaterial1, imageMaterial1, imageMaterial1, imageMaterial1]
        //add box to scene
        let wallNode = SCNNode(geometry: wall)
        wallNode.position = SCNVector3(CGFloat(position.xCoord), CGFloat(position.yCoord), CGFloat(position.zCoord))
        mazeWallNode.addChildNode(wallNode)
        mazeWallNode.castsShadow = true
        ARCanvas.scene.rootNode.addChildNode(mazeWallNode)
    }
    
    // creates the maze floor
    func setupFloor(size: Size, position: Position)
    {
        let floor = SCNBox(width: CGFloat(size.width), height: CGFloat(size.height), length: CGFloat(size.length), chamferRadius: 0)
        
        //wall textures
        let imageMaterial1 = SCNMaterial()
        let imageMaterial2 = SCNMaterial()
        
        let floorImage1 = UIImage(named: "floor")
        let floorSideImage1 = UIImage(named: "wall")
        
        imageMaterial1.diffuse.contents = floorImage1
        imageMaterial2.diffuse.contents = floorSideImage1
        
        //apply skins
        floor.materials = [imageMaterial2, imageMaterial2, imageMaterial2, imageMaterial2, imageMaterial1, imageMaterial2]
        //add box to scene
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(CGFloat(position.xCoord), CGFloat(position.yCoord), CGFloat(position.zCoord))
        mazeFloorNode.addChildNode(floorNode)
        mazeWallNode.castsShadow = true
        ARCanvas.scene.rootNode.addChildNode(mazeFloorNode)
    }
    
    //create a maze
    func setUpMaze(position: Position)
    {
        //dimensions of a box
        let WIDTH = 0.04
        let HEIGHT = 0.04
        let LENGTH = 0.04
        //init dimensions
        let dimensions = Size(width: WIDTH, height: HEIGHT, length: LENGTH)
        
        let FLOORHEIGHT = 0.01
        let floorDimensions = Size(width: WIDTH, height: FLOORHEIGHT, length: LENGTH)
        //position of first box
        var x = position.xCoord - WIDTH * Double(NUMCOL) / 2.0
        var y = position.yCoord + 0.06
        var z = position.zCoord - LENGTH * Double(NUMROW) / 2.0
        let c = 0.0
        //init position
        var location = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
        var playerLocation = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
        var bossLocation = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
        var minionLocation = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
        let NUMROW = Maze().getHeight()
        let NUMCOL = Maze().getWidth()
        
        var minionCount = 1;
        
        for i in 0 ..< NUMROW
        {
            for j in 0 ..< NUMCOL
            {
                let row = maze[i]
                let flag = row[j]
                
                //creates maze floor
                //y offset to place floor block flush under the wall
                y -= (HEIGHT + FLOORHEIGHT) / 2
                location = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
                setupFloor(size: floorDimensions, position: location)
                y += (HEIGHT + FLOORHEIGHT) / 2
                
                //show wall or player depending on flag value
                if flag == WALL
                {
                    location = Position(xCoord: x, yCoord: y, zCoord: z, cRad: c)
                    setupWall(size: dimensions, position: location)
                }
                else if flag == PLAYER
                {
                    //initial player position
                    playerLocation = Position(xCoord: x, yCoord: y-(HEIGHT/2), zCoord: z, cRad: c)
                    player.spawnPlayer(ARCanvas, playerLocation)
                }
                else if flag == BOSS
                {
                    bossLocation = Position(xCoord: x, yCoord: y-(HEIGHT/2), zCoord: z, cRad: c)
                    let boss = Boss(position: bossLocation)
                    bossPool.append(boss.spawnBoss(ARCanvas, bossLocation))
                }
				else if flag == MINION
                {
                    minionLocation = Position(xCoord: x, yCoord: y-(HEIGHT/2), zCoord: z, cRad: c)
                    let minion = Minion()
                    minion.setLocation(location: (row: i, col: j))
                    minionPool.append(minion.spawnMinion(ARCanvas, minionLocation, minionCount))
                    minionCount+=1
                }
                //increment each block so it lines up horizontally
                x += WIDTH
            }
            //line up blocks on a new row
            x -= WIDTH * Double(NUMCOL)
            z += LENGTH
        }
    }
    
    //dismisses the maze and returns to menu
    func restart()
    {
        presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
    
    //continue to the next stage
    func loadNextLevel()
    {
        ARCanvas.scene.rootNode.enumerateChildNodes
        {
            (node, stop) in node.removeFromParentNode()
        }
        
        //reset player
        let hp = player.getHP()
        player = Player(name: "noobMaster69", maxHP: 10, health: hp, minAtkVal: 1, maxAtkVal: 3, level: 1)

        //reset maze
        maze = Maze().newStage()
        setUpMaze(position: location)
        
        //reload music and settings
        setupDungeonMusic()
        //setupARLight()
        //setupFog()
    }
}
