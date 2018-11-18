//
//  GameScene.swift
//  LifeOfAReferee
//
//  Created by Samar Sunkaria on 11/10/18.
//  Copyright © 2018 Deep in the sea. All rights reserved.
//

import SpriteKit

enum GameLayers: Int {
    case background = -6
    case foreground
    case ksjdnfknsefn
    case skjdbfkjd
    case lihdfkjwrf
    case wehfwef
}

struct CollisionMasks {
    static let grass: UInt32 = 0x1 << 0
    static let referee: UInt32 = 0x1 << 1
    static let ball: UInt32 = 0x1 << 2
    static let redCard: UInt32 = 0x1 << 3
    static let yellowCard: UInt32 = 0x1 << 4
}

class GameScene: SKScene {

//    let node = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 20))
    let grassWidth = SKSpriteNode(imageNamed: "Grass").size.width - 0.5
    let grassHeight = SKSpriteNode(imageNamed: "Grass").size.height - 25.0

    var referee: SKSpriteNode?

    override func didMove(to view: SKView) {
        backgroundColor = .darkGray

//        view.showsPhysics = true
        physicsWorld.contactDelegate = self

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -12)

        
        createBackground()
        createGrass()
        createReferee()
        createBall()
    }

    func createBackground() {
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = self.size
        background.anchorPoint = .zero
        background.position = .zero
        background.name = "Background"
        background.zPosition = -2

        addChild(background)
    }

    func createBall() {
        let ball = SKSpriteNode(imageNamed: "Ball")
        ball.anchorPoint = .zero
        ball.position = CGPoint(x: 500, y: grassHeight)
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
        ball.physicsBody?.applyImpulse(CGVector(dx: -200, dy: 0))
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
            grass.physicsBody?.applyImpulse(CGVector(dx: -200, dy: 0))
        }

    }

    func createReferee() {
        let referee = SKSpriteNode(imageNamed: "Referee")
        referee.anchorPoint = .zero
        referee.position = CGPoint(x: 100, y: grassHeight)
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

    let velocity: CGFloat = 400

    var lastUpdate: TimeInterval?

    func timeAdjuestedVelocity(for currentTime: TimeInterval) -> CGFloat {
        guard let lastUpdate = lastUpdate else { return 0 }
        return velocity * CGFloat((currentTime - lastUpdate))
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
                node.position.x = self.view?.frame.width ?? 1000
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
        if (referee?.frame.origin.y ?? 0) <= grassHeight + 1 {
            referee?.physicsBody?.velocity = .zero
            referee?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 500))
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


        print(CollisionMasks.grass)
        print(CollisionMasks.referee)
        print(contact.bodyA.categoryBitMask)
        print(contact.bodyB.categoryBitMask)

        if contact.bodyA.categoryBitMask == CollisionMasks.grass, contact.bodyB.categoryBitMask == CollisionMasks.referee {
            referee?.texture = SKTexture(image: #imageLiteral(resourceName: "Referee"))
        }

        if contact.bodyA.categoryBitMask == CollisionMasks.referee, contact.bodyB.categoryBitMask == CollisionMasks.grass ||
            contact.bodyB.categoryBitMask == CollisionMasks.referee, contact.bodyA.categoryBitMask == CollisionMasks.grass {
            referee?.texture = SKTexture(image: #imageLiteral(resourceName: "Referee"))
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
