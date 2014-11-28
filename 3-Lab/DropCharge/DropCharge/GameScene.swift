//
//  GameScene.swift
//  DropCharge
//
//  Created by Main Account on 11/23/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import SpriteKit
import CoreMotion
import AVFoundation
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

  // MARK: Properties
  var lastUpdateTime: NSTimeInterval = 0
  var dt: NSTimeInterval = 0
  let motionManager = CMMotionManager()
  var xAcceleration = CGFloat(0)
  var gameState = GameState.WaitingForTap
  var title: SKSpriteNode!
  let worldNode = SKNode()
  var bgNode = BackgroundNode()
  var mgNode = MidgroundNode()
  let fgNode = SKNode()
  var level = LevelNode()
  var player = SKSpriteNode(imageNamed: "player01_fall_1.png")
  let bomb = SKSpriteNode(imageNamed: "bomb_1")
  var soundManager: SoundManager!
  var lava: LavaNode!
  var lives = 3
  
  // MARK: Init
  override func didMoveToView(view: SKView) {
    setupLevel()
    setupNodes()
    setupPlayer()
    setupPhysics()
    setupMusic()
    setupLava()
    setupCoreMotion()
  }

  func setupLevel() {
  
    title = SKSpriteNode(imageNamed: "DropCharge_title")
    title.position = CGPoint(x: size.width/2, y: size.height * 0.7)
    title.zPosition = 100
    addChild(title)
    
  }

  func setupNodes() {

    addChild(worldNode)
    worldNode.addChild(bgNode)
    worldNode.addChild(mgNode)
    worldNode.addChild(fgNode)
    
    level.zPosition = ForegroundZ.Level.rawValue
    fgNode.addChild(level)

  }

  func setupPlayer() {
  
    player.position = CGPoint(x: size.width / 2, y: 80)
    player.zPosition = ForegroundZ.Player.rawValue
    
    player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
    player.physicsBody?.dynamic = false
    player.physicsBody?.allowsRotation = false
    player.physicsBody?.restitution = 1.0
    player.physicsBody?.friction = 0.0
    player.physicsBody?.angularDamping = 0.0
    player.physicsBody?.linearDamping = 0.0
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player
    player.physicsBody?.collisionBitMask = 0
    
    fgNode.addChild(player)
    
  }

  func setupPhysics() {
    physicsWorld.contactDelegate = self
  }
  
  func setupMusic() {
    soundManager = SoundManager(node: self)
    soundManager.playMusicBackground()
  }
  
  func setupLava() {
    lava = LavaNode(useEmitter: true)
    lava.position = CGPoint(x: size.width/2, y: -300)
    fgNode.addChild(lava)
  }
  
  func setupCoreMotion() {
    motionManager.accelerometerUpdateInterval = 0.2
    motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {
      (accelerometerData: CMAccelerometerData!, error: NSError!) in
      let acceleration = accelerometerData.acceleration
      self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
    })
  }
  
  // MARK: Game State
  
  func switchToWaitingForBomb() {
  
    // Switch game state
    gameState = .WaitingForBomb
    
    // Scale out title
    title.runAction(SKAction.scaleTo(0, duration: 0.5))
    
    // Add bomb
    bomb.position = CGPoint(x: player.position.x, y: player.position.y)
    bomb.zPosition = ForegroundZ.Bomb.rawValue
    fgNode.addChild(bomb)
    
    // Bounce bomb
    let scaleUp = SKAction.scaleTo(1.25, duration: 0.25)
    let scaleDown = SKAction.scaleTo(1.0, duration: 0.25)
    let sequence = SKAction.sequence([scaleUp, scaleDown])
    let repeat = SKAction.repeatActionForever(sequence)
    bomb.runAction(repeat)
    
    // Switch to playing state
    runAction(SKAction.sequence([
      SKAction.waitForDuration(2.0),
      SKAction.runBlock(switchToPlaying)
    ]))
    
    // Play sounds
    soundManager.playSoundBombDrop()
    soundManager.playSoundTickTock()
    
  }
  
  func switchToPlaying() {
  
    // Switch game state
    gameState = .Playing
    
    // Stop bomb
    bomb.removeFromParent()
    
    // Start player movement
    player.physicsBody!.dynamic = true
    superBoostPlayer()
    
    // Play sounds
    soundManager.playMusicAction()
    soundManager.playSoundSuperBoost()
    
    // Set off the bomb!
    let emitter = SKEmitterNode(fileNamed: "BigExplosion")
    emitter.position = bomb.position
    fgNode.addChild(emitter)
    emitter.runAction(SKAction.removeFromParentAfterDelay(2.0))
    
  }
  
  func switchToGameOver() {
  
    // Switch game state
    gameState = .GameOver
    
    // Turn off physics
    physicsWorld.contactDelegate = nil
    player.physicsBody?.dynamic = false
    
    // Sound effects
    soundManager.playMusicBackground()
    
    // Bounce player
    let moveUpAction = SKAction.moveByX(0, y: size.height/2, duration: 0.5)
    moveUpAction.timingMode = .EaseOut
    let moveDownAction = SKAction.moveByX(0, y: -size.height, duration: 1.0)
    moveDownAction.timingMode = .EaseIn
    let sequence = SKAction.sequence([moveUpAction, moveDownAction])
    player.runAction(sequence)
    
    // Game Over
    let gameOver = SKSpriteNode(imageNamed: "GameOver")
    gameOver.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(gameOver)
  
  }
  
  // MARK: Touch Handling
  
  func handlePlayingTouches(touches: NSSet) {
    if let touch = touches.anyObject() as? UITouch {
      let touchTarget = touch.locationInNode(self)
      let xVelocity = touchTarget.x < player.position.x ? CGFloat(-150.0) : CGFloat(150.0)
      player.physicsBody!.velocity = CGVector(dx: xVelocity, dy: player.physicsBody!.velocity.dy)
    }
  }
  
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    switch gameState {
      case .WaitingForTap:
        switchToWaitingForBomb()
      case .Playing:
        handlePlayingTouches(touches)
      case .GameOver:
        let newScene = GameScene(size: size)
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        self.view?.presentScene(newScene, transition: reveal)
      default:
        break;
    }
  }
  
  override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
    switch gameState {
      case .Playing:
        handlePlayingTouches(touches)
      default:
        break;
    }
  }
  
  // MARK: Update
  
  override func update(currentTime: NSTimeInterval) {
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    
    if gameState == .Playing {
      updateCamera()
      updatePlayer()
      bgNode.update(lastUpdateTime)
      mgNode.update(lastUpdateTime)
      level.update()
      lava.update(dt)
      updateCollisionLava()
    }
  }
  
  func updateCamera() {
  
    let target = player.position
    var targetPosition = CGPoint(x: worldNode.position.x, y: -(target.y - size.height * 0.4))
    targetPosition.y = min(targetPosition.y, -(lava.position.y))
    var newPosition = targetPosition
    
    self.fgNode.position = newPosition
    self.mgNode.position = CGPoint(x: newPosition.x/5.0, y: newPosition.y/5.0)
    self.bgNode.position = CGPoint(x: newPosition.x/10.0, y: newPosition.y/10.0)
    
  }
  
  func updatePlayer() {
    // Set velocity based on core motion
    player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
    
    // Wrap player across edges of screen
    if player.position.x < player.size.width/2 {
      player.position.x += size.width
    }
    else if player.position.x > size.width+player.size.width/2 {
      player.position.x -= size.width
    }
  }
  
  func updateCollisionLava() {
    if player.position.y < lava.position.y + 90 {
      soundManager.playSoundHitLava()
      boostPlayer()
      
      lives--
      if lives <= 0 {
        switchToGameOver()
      }
    }
  }
    
  // MARK: Contacts
  
  func didBeginContact(contact: SKPhysicsContact) {
 
    let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
    
    switch other.categoryBitMask {
      case PhysicsCategory.CoinNormal:
        if let coin = other.node as? SKSpriteNode {
          coin.removeFromParent()
          jumpPlayer()
          soundManager.playSoundCoin()
        }
      case PhysicsCategory.CoinSpecial:
        if let coin = other.node as? SKSpriteNode {
          coin.removeFromParent()
          boostPlayer()
          soundManager.playSoundBoost()
        }
      case PhysicsCategory.PlatformNormal:
        if let platform = other.node as? SKSpriteNode {
          if (player.physicsBody?.velocity.dy < 0) {
            jumpPlayer()
            soundManager.playSoundJump()
          }
        }
      case PhysicsCategory.PlatformBreakable:
        if let platform = other.node as? SKSpriteNode {
          if (player.physicsBody?.velocity.dy < 0) {
            platform.removeFromParent()
            jumpPlayer()
            soundManager.playSoundBrick()
          }
        }
      default:
      break;
    }
 
  }
  
  // MARK: Helpers
  func setPlayerVelocity(amount:CGFloat) {
    player.physicsBody!.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: max(player.physicsBody!.velocity.dy, amount))
  }
  
  func jumpPlayer() {
    setPlayerVelocity(650)
  }
  
  func boostPlayer() {
    setPlayerVelocity(1000)
  }
  
  func superBoostPlayer() {
    setPlayerVelocity(1500)
  }
  
}