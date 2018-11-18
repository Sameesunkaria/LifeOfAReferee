//
//  GameScene.swift
//  LifeOfAReferee
//
//  Created by Samar Sunkaria on 11/10/18.
//  Copyright © 2018 Deep in the sea. All rights reserved.
//

import SpriteKit

enum GameLayers: CGFloat {
    case background = -6
    case grass
    case referee
    case gameObject
}

struct CollisionMasks {
    static let grass: UInt32 = 0x1 << 0
    static let referee: UInt32 = 0x1 << 1
    static let ball: UInt32 = 0x1 << 2
    static let redCard: UInt32 = 0x1 << 3
    static let yellowCard: UInt32 = 0x1 << 4
}

enum GameObject: CaseIterable {
    case ball
    case redCard
    case yellowCard
    case nothing

    static func probabilities(for object: GameObject) -> Int {
        switch object {
        case .ball: return 2
        case .redCard: return 1
        case .yellowCard: return 4
        case .nothing: return 4
        }
    }
}

class GameScene: SKScene {

    let grassWidth = SKSpriteNode(imageNamed: "Grass").size.width - 0.5
    let grassHeight = SKSpriteNode(imageNamed: "Grass").size.height - 25.0

    let scoreSound = SKAction.playSoundFileNamed("ShortWhistle.m4a", waitForCompletion: false)
    let gameEndSound = SKAction.playSoundFileNamed("LongWhistle.m4a", waitForCompletion: false)

    var score = 0
    var playing = false

    var referee: SKSpriteNode?

    override func didMove(to view: SKView) {
        backgroundColor = .darkGray

//        view.showsPhysics = true
        physicsWorld.contactDelegate = self

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -12)

        createScene()
        
//        createBackground()
//        createGrass()
//        createReferee()
////        createBall()
//
//        startDisplayingGameObjects()
//        createScoreLabel()


    }

    var scoreLabel = SKLabelNode()

    func createScene() {
        createBackground()
        createGrass()
        createReferee()

        createScoreLabel()
    }

    func stopGame() {
        self.removeAllActions()
        self.removeAllChildren()


        playing = false
        score = 0


        createScene()
        run(gameEndSound)
    }

    func startGame() {

        setRefereeInMotion()
        setGrassInMotion()
        startDisplayingGameObjects()

        playing = true
    }

    func createScoreLabel() {
        guard let view = view else { return }
        let labelNode = SKLabelNode(attributedText: attributedString(for: score))
        labelNode.position = CGPoint(x: view.frame.width - labelNode.frame.width/2 - 20 - view.safeAreaInsets.right, y: view.frame.height - labelNode.frame.height/2 - 40 - view.safeAreaInsets.top)
        addChild(labelNode)
        scoreLabel = labelNode
    }


    func attributedString(for score: Int) -> NSAttributedString {
        let pointString = "\(score) pts"
        let attributedString = NSMutableAttributedString(string: pointString)
        let start = attributedString.length - 3
        let length = 3

        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 15, weight: .heavy)], range: NSRange(location: start, length: length))
        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 48, weight: .heavy)], range: NSRange(location: 0, length: attributedString.length - 4))
        attributedString.addAttributes([.foregroundColor: #colorLiteral(red: 0.3291337788, green: 0.3291337788, blue: 0.3291337788, alpha: 1)], range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }

    func startDisplayingGameObjects() {
        var probabilityMap = [GameObject]()

        for object in GameObject.allCases {
            for _ in 0..<GameObject.probabilities(for: object) {
                probabilityMap.append(object)
            }
        }

        var lastObject = GameObject.yellowCard

        let wait = SKAction.wait(forDuration: 0.5)
        let timedAction = SKAction.run {
            let randomValue = Int.random(in: 0..<probabilityMap.count)

            switch probabilityMap[randomValue] {
            case .ball:
                if lastObject != .ball {
                    self.createBall()
                }
            case .nothing: break
            case .redCard: self.createRedCard()
            case .yellowCard: self.createYellowCard()
            }

            lastObject = probabilityMap[randomValue]

            self.enumerateChildNodes(withName: "Grass") { (node, _) in
                node.physicsBody?.applyImpulse(CGVector(dx: self.impulseDelta, dy: 0))
            }

            self.enumerateChildNodes(withName: "Ball") { (node, _) in
                node.physicsBody?.applyImpulse(CGVector(dx: self.impulseDelta, dy: 0))
            }

            self.enumerateChildNodes(withName: "Red Card") { (node, _) in
                node.physicsBody?.applyImpulse(CGVector(dx: self.impulseDelta, dy: 0))
            }

            self.enumerateChildNodes(withName: "Yellow Card") { (node, _) in
                node.physicsBody?.applyImpulse(CGVector(dx: self.impulseDelta, dy: 0))
            }

            self.impulse += self.impulseDelta

        }

        run(SKAction.repeatForever(SKAction.sequence([wait, timedAction])))


    }

    func createBackground() {
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = self.size
        background.anchorPoint = .zero
        background.position = .zero
        background.name = "Background"
        background.zPosition = GameLayers.background.rawValue

        addChild(background)
    }

    var impulse: CGFloat = -400
    let impulseDelta: CGFloat = -5

    func createBall() {
        let ball = SKSpriteNode(imageNamed: "Ball")
        ball.anchorPoint = .zero
        ball.position = CGPoint(x: frame.width, y: grassHeight)
        ball.zPosition = GameLayers.gameObject.rawValue
        ball.name = "Ball"

        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.frame.width/2, center: CGPoint(x: ball.frame.width/2, y: ball.frame.height/2))
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.mass = 1
        ball.physicsBody?.restitution = 0
        ball.physicsBody?.categoryBitMask = CollisionMasks.ball
        ball.physicsBody?.collisionBitMask = 0
        ball.physicsBody?.contactTestBitMask = CollisionMasks.referee
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.isDynamic = true

        addChild(ball)
        ball.physicsBody?.applyImpulse(CGVector(dx: impulse, dy: 0))
    }

    let cardOffset: CGFloat = 20

    func createYellowCard() {
        let card = SKSpriteNode(imageNamed: "Yellow Card")
        card.anchorPoint = .zero
        card.position = CGPoint(x: frame.width, y: grassHeight + cardOffset)
        card.zPosition = GameLayers.gameObject.rawValue
        card.name = "Yellow Card"

        card.physicsBody = SKPhysicsBody(rectangleOf: card.frame.size, center: CGPoint(x: card.frame.width/2, y: card.frame.height/2))
        card.physicsBody?.linearDamping = 0
        card.physicsBody?.mass = 1
        card.physicsBody?.restitution = 0
        card.physicsBody?.categoryBitMask = CollisionMasks.yellowCard
        card.physicsBody?.collisionBitMask = 0
        card.physicsBody?.contactTestBitMask = CollisionMasks.referee
        card.physicsBody?.affectedByGravity = false
        card.physicsBody?.isDynamic = true

        addChild(card)
        card.physicsBody?.applyImpulse(CGVector(dx: impulse, dy: 0))
    }

    func createRedCard() {
        let card = SKSpriteNode(imageNamed: "Red Card")
        card.anchorPoint = .zero
        card.position = CGPoint(x: frame.width, y: grassHeight + cardOffset)
        card.zPosition = GameLayers.gameObject.rawValue
        card.name = "Red Card"

        card.physicsBody = SKPhysicsBody(rectangleOf: card.frame.size, center: CGPoint(x: card.frame.width/2, y: card.frame.height/2))
        card.physicsBody?.linearDamping = 0
        card.physicsBody?.mass = 1
        card.physicsBody?.restitution = 0
        card.physicsBody?.categoryBitMask = CollisionMasks.redCard
        card.physicsBody?.collisionBitMask = 0
        card.physicsBody?.contactTestBitMask = CollisionMasks.referee
        card.physicsBody?.affectedByGravity = false
        card.physicsBody?.isDynamic = true

        addChild(card)
        card.physicsBody?.applyImpulse(CGVector(dx: impulse, dy: 0))
    }

    func createGrass() {
        let screenWidth = scene?.frame.width ?? 0

        let numberOfGrassTiles = Int((screenWidth / grassWidth).rounded(.up)) + 1

        let ground = SKSpriteNode(color: .clear, size: CGSize(width: view?.frame.width ?? 0, height: grassHeight))
        ground.anchorPoint = .zero
        ground.position = .zero
        ground.name = "Ground"

        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.frame.size, center: CGPoint(x: ground.frame.width/2, y: ground.frame.height/2))
        ground.physicsBody?.categoryBitMask = CollisionMasks.grass
        ground.physicsBody?.collisionBitMask = 0
        ground.physicsBody?.contactTestBitMask = CollisionMasks.referee
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.isDynamic = false

        addChild(ground)


        for index in 0..<numberOfGrassTiles {
            let grass = SKSpriteNode(imageNamed: "Grass")
            grass.anchorPoint = .zero
            grass.position = CGPoint(x: CGFloat(index) * grassWidth, y: 0)
            grass.zPosition = GameLayers.grass.rawValue
            grass.name = "Grass"

            grass.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: grassWidth, height: grassHeight), center: CGPoint(x: grass.frame.width/2, y: grassHeight/2))
            grass.physicsBody?.categoryBitMask = 0
            grass.physicsBody?.mass = 1
            grass.physicsBody?.collisionBitMask = 0
            grass.physicsBody?.contactTestBitMask = 0
            grass.physicsBody?.affectedByGravity = false
            grass.physicsBody?.linearDamping = 0.0
//            grass.physicsBody?.isDynamic = false

            addChild(grass)
        }

    }

    func setGrassInMotion() {
        enumerateChildNodes(withName: "Grass") { (node, _) in
            node.physicsBody?.applyImpulse(CGVector(dx: self.impulse, dy: 0))
        }
    }

    var repeatAction = SKAction()

    let refereeAtlas = SKTextureAtlas(named: "Sprites")

    func createReferee() {
        let referee = SKSpriteNode(texture: refereeAtlas.textureNamed("Referee1"))
//            SKSpriteNode(imageNamed: "Referee")
        referee.anchorPoint = .zero
        referee.position = CGPoint(x: 100, y: grassHeight)
        referee.zPosition = GameLayers.referee.rawValue
        referee.name = "Referee"


        referee.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: referee.frame.width/2, height: referee.frame.height), center: CGPoint(x: referee.frame.width/2, y: referee.frame.height/2))
        referee.physicsBody?.linearDamping = 1.2
        referee.physicsBody?.restitution = 0
        referee.physicsBody?.allowsRotation = false
        referee.physicsBody?.categoryBitMask = CollisionMasks.referee
        referee.physicsBody?.collisionBitMask = CollisionMasks.grass
        referee.physicsBody?.contactTestBitMask = CollisionMasks.grass
        referee.physicsBody?.affectedByGravity = true
        referee.physicsBody?.isDynamic = true


        addChild(referee)

        self.referee = referee

    }

    func setRefereeInMotion() {
        let animatedReferee = SKAction.animate(with: [
            refereeAtlas.textureNamed("Referee1"),
            refereeAtlas.textureNamed("Referee2")
            ], timePerFrame: 0.1)

        repeatAction = SKAction.repeatForever(animatedReferee)
        referee?.run(repeatAction)
    }

    override func update(_ currentTime: TimeInterval) {

        var outOfFrameGrass: SKNode?
        var lastNode: SKNode?

        enumerateChildNodes(withName: "Grass") { (node, _) in
            if self.isOutsideFrame(node: node) {
                outOfFrameGrass = node
            }

            if let lNode = lastNode {
                if lNode.position.x < node.position.x {
                    lastNode = node
                }
            } else {
                lastNode = node
            }

        }

        outOfFrameGrass?.position.x = (lastNode?.position.x ?? 0) + grassWidth

        enumerateChildNodes(withName: "Ball") { (node, _) in

            if self.isOutsideFrame(node: node) {
                self.removeChildren(in: [node])
            }
        }

        enumerateChildNodes(withName: "Yellow Card") { (node, _) in

            if self.isOutsideFrame(node: node) {
                self.removeChildren(in: [node])
            }
        }

        enumerateChildNodes(withName: "Red Card") { (node, _) in

            if self.isOutsideFrame(node: node) {
                self.removeChildren(in: [node])
            }
        }
    }

    func isOutsideFrame(node: SKNode) -> Bool {
        let width = node.frame.width
        if node.frame.origin.x < -width {
            return true
        }

        return false
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !playing {
            startGame()
            return
        }

        if (referee?.frame.origin.y ?? 0) <= grassHeight + 1 {
            referee?.physicsBody?.velocity = .zero
            referee?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 600))
            referee?.isPaused = true
            referee?.texture = SKTexture(image: #imageLiteral(resourceName: "RefereeJumping"))
        }
    }

    
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {

        enumerateChildNodes(withName: "Ball") { (node, _) in
            if contact.bodyA == node.physicsBody || contact.bodyB == node.physicsBody {
                print("Did touch the ball")
            }
        }


//        print(CollisionMasks.grass)
//        print(CollisionMasks.referee)
//        print(contact.bodyA.categoryBitMask)
//        print(contact.bodyB.categoryBitMask)

//        if contact.bodyA.categoryBitMask == CollisionMasks.grass, contact.bodyB.categoryBitMask == CollisionMasks.referee {
////            referee?.texture = SKTexture(image: #imageLiteral(resourceName: "Referee"))
//        }

        if (contact.bodyA.categoryBitMask == CollisionMasks.grass && contact.bodyB.categoryBitMask == CollisionMasks.referee) ||
            (contact.bodyB.categoryBitMask == CollisionMasks.grass && contact.bodyA.categoryBitMask == CollisionMasks.referee) {
            referee?.texture = refereeAtlas.textureNamed("Referee1")
            referee?.isPaused = false
        }

        if (contact.bodyA.categoryBitMask == CollisionMasks.referee && contact.bodyB.categoryBitMask == CollisionMasks.ball) ||
            (contact.bodyB.categoryBitMask == CollisionMasks.referee && contact.bodyA.categoryBitMask == CollisionMasks.ball) {
            score = 0
            removeChildren(in: [scoreLabel])
            createScoreLabel()
            stopGame()
        }

        if (contact.bodyA.categoryBitMask == CollisionMasks.referee && contact.bodyB.categoryBitMask == CollisionMasks.yellowCard) ||
            (contact.bodyB.categoryBitMask == CollisionMasks.referee && contact.bodyA.categoryBitMask == CollisionMasks.yellowCard) {
            score += 1
            removeChildren(in: [scoreLabel])
            createScoreLabel()
            run(scoreSound)


            if contact.bodyA.categoryBitMask == CollisionMasks.yellowCard {
                removeChildren(in: [contact.bodyA.node ?? SKNode()])
            } else {
                removeChildren(in: [contact.bodyB.node ?? SKNode()])
            }

        }

        if (contact.bodyA.categoryBitMask == CollisionMasks.referee && contact.bodyB.categoryBitMask == CollisionMasks.redCard) ||
            (contact.bodyB.categoryBitMask == CollisionMasks.referee && contact.bodyA.categoryBitMask == CollisionMasks.redCard) {
            score += 2
            removeChildren(in: [scoreLabel])
            createScoreLabel()
            run(scoreSound)

            if contact.bodyA.categoryBitMask == CollisionMasks.redCard {
                removeChildren(in: [contact.bodyA.node ?? SKNode()])
            } else {
                removeChildren(in: [contact.bodyB.node ?? SKNode()])
            }
        }


//        print("DID BEGIN")
//        print(contact)
//        print("")
    }

    func didEnd(_ contact: SKPhysicsContact) {
//        print("DID END")
//        print(contact)
//        print("")
    }
}
