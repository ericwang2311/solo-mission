//  control l to reformat code
//  GameScene.swift
//  Solo Mission
//
//  Created by Eric Wang on 6/20/18.
//  Copyright © 2018 Eric Wang. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate { //physics creates contact
    
    let player = SKSpriteNode(imageNamed: "playerShip")
    
//    let bulletSound = SKAction.playSoundFileNamed(putfilenamehere, waitForCompletion: false)
    
    struct PhysicsCategories{
        static let None: UInt32 = 0
        static let Player: UInt32 = 0b1 // 1
        static let Bullet: UInt32 = 0b10 //2
        static let Enemy: UInt32 = 0b100 //4 cause 3 means player and bullet
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min min:CGFloat,max: CGFloat) -> CGFloat {
        return random() * (max - min) + min //generate rand number between min max range
    }
    
    
    let gameArea: CGRect //area the game will be locked in
    
    override init(size:CGSize) {
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect (x: margin, y: 0, width: playableWidth, height: size.height) //rectangle seen on all devices
        
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) { //anything here happens straight away
        self.physicsWorld.contactDelegate = self // allows for physics in this scene
        
        let background = SKSpriteNode(imageNamed: "background") //SKSpriteNode is an image
        background.size = self.size // sets background same size as the scene
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        background.zPosition = 0 // layering of object
        self.addChild(background) // fully makes the background
        
        player.setScale(1) //increase this number for a bigger ship
        player.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.2) //starts ship 20%
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size) // hitbox
        player.physicsBody!.affectedByGravity = false // now player has a body unaffected by gravity
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player // assigns physics body of player into a physics category
        player.physicsBody!.collisionBitMask = PhysicsCategories.None // tells not to collide with anything and can only make contact
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy // lets enemy hit us
        player.zPosition = 2
        self.addChild(player)
        
        startNewLevel() //starts spawning the enemies
    }
    
    func didBegin(contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        else{
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
    }
    
    
    
    
    
    
    
    
    func startNewLevel(){
        
        let spawn = SKAction.run(spawnEnemy) //spawns new enemy
        let waitToSpawn = SKAction.wait(forDuration:1) //time till next enemy spawns
        let spawnSequence = SKAction.sequence([spawn,waitToSpawn])
        let spawnForever = SKAction.repeatForever(spawnSequence) //always spawns enemies
        self.run(spawnForever)
    }
    
    
    
    func fireBullet () {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.setScale(1)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None //prevents bullet from colliding with anything
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy // bullet can hit enemy
        
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([moveBullet,deleteBullet]) // list of actions in order // put bulletSound in front if I have sound
        bullet.run(bulletSequence)
    }
    
    func spawnEnemy () {
        
        let randomXStart = random(min: gameArea.minX, max: gameArea.maxX)
        let randomXEnd = random(min: gameArea.minX, max: gameArea.maxX)
        
        let startPoint = CGPoint (x: randomXStart, y: self.size.height * 1.2) //where ship will spawn
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "enemyShip")
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2 //layering of image
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None //prevents enemy from colliding with anything
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet //decides what enemy can touch
        
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.5) //enemy movement
        let deleteEnemy = SKAction.removeFromParent() //clears enemy if they move offscreen
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy])
        enemy.run(enemySequence)
        
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy,dx) //figures out how much enemy needs to rotate
        enemy.zRotation = amountToRotate
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet() // when you touch the screen, a bullet fires
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches{
            let pointOfTouch = touch.location(in:self) //where we are touching
            let previousPointOfTouch = touch.previousLocation(in:self)
            
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            player.position.x += amountDragged //moves player left or right
            
            if player.position.x > gameArea.maxX - player.size.width/2{ // if too far right bump ship back to furthest right point
                player.position.x = gameArea.maxX - player.size.width/2
        }
            if player.position.x < gameArea.minX + player.size.width/2{ // if too far left bump ship back to furthest right point
                player.position.x = gameArea.minX + player.size.width/2
    }
    }
    
    }}
