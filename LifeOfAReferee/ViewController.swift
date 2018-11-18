//
//  ViewController.swift
//  LifeOfAReferee
//
//  Created by Samar Sunkaria on 11/10/18.
//  Copyright © 2018 Deep in the sea. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    var gameScene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()

        let gameScene = GameScene(size: view.bounds.size)
        let skView = view as! SKView
//        skView.showsFPS = true
//        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = false

        gameScene.scaleMode = .aspectFill
        skView.presentScene(gameScene)
        self.gameScene = gameScene
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameScene?.showLabels()
    }

    override var shouldAutorotate: Bool {
        return false
    }

}

