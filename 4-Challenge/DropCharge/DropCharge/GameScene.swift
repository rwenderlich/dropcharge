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

enum GameState {
case WaitingForTap
case WaitingForBomb
case Playing
case GameOver
}

struct PhysicsCategory {
static let None: UInt32              = 0
static let Player: UInt32            = 0b1      // 1
static let PlatformNormal: UInt32    = 0b10     // 2
static let PlatformBreakable: UInt32 = 0b100    // 4
static let CoinNormal: UInt32        = 0b1000   // 8
static let CoinSpecial: UInt32       = 0b10000  // 16
static let Edges: UInt32             = 0b100000 // 32
}

enum ForegroundZ: CGFloat {
case Platforms
case Bomb
case Coins
case Lava
case Player
}

class GameScene: SKScene, SKPhysicsContactDelegate {

  // MARK: Properties
  let worldNode = SKNode()
  var bgNode: RepeatableNode!
  var mgNode: RepeatableNode!
  let fgNode = SKNode()
  var lastUpdateTime: NSTimeInterval = 0
  var dt: NSTimeInterval = 0
  var player = SKSpriteNode(imageNamed: "player01_fall_1.png")
  var gameState = GameState.WaitingForTap
  var lava: SKNode = SKNode()
  var visibleMinYFg = CGFloat(0)
  var visibleMaxYFg = CGFloat(0)
  let motionManager = CMMotionManager()
  var xAcceleration = CGFloat(0)
  var lives = 3
  let title = SKSpriteNode(imageNamed: "DropCharge_title")
  let bomb = SKSpriteNode(imageNamed: "bomb_1")
  var playerTrail: SKEmitterNode! = nil
  var animJump: SKAction! = nil
  var animFall: SKAction! = nil
  var animSteerLeft: SKAction! = nil
  var animSteerRight: SKAction! = nil
  var curAnim: SKAction? = nil
  var timeSinceLastExplosion: CGFloat = 0
  var timeForNextExplosion: CGFloat = 0
  var soundManager: SoundManager!
  var level: LevelNode!
  
  // MARK: Init
  override func didMoveToView(view: SKView) {
    setupMusic()
    setupPhysics()
    setupNodes()
    setupPlayer()
    setupLevel()
    setupLava()
    setupCoreMotion()
  }
  
  func setupMusic() {
    soundManager = SoundManager(node: self)
    soundManager.playMusicBackground()
  }
  
  func setupPhysics() {
    physicsWorld.contactDelegate = self
  }
  
  func setupNodes() {
    
    addChild(worldNode)
    bgNode = RepeatableNode(prefix: "bg_", number: 3, containerSize: size)
    worldNode.addChild(bgNode)
    mgNode = RepeatableNode(prefix: "midground_", number: 4, containerSize: size)
    worldNode.addChild(mgNode)
    worldNode.addChild(fgNode)
    level = LevelNode(size: size)
    fgNode.addChild(level)
  }
  
  func setupPlayer() {
    player.position = CGPoint(x: size.width / 2, y: 80)
    player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
    player.physicsBody?.dynamic = false
    player.physicsBody?.allowsRotation = false
    player.physicsBody?.restitution = 1.0
    player.physicsBody?.friction = 0.0
    player.physicsBody?.angularDamping = 0.0
    player.physicsBody?.linearDamping = 0.0
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player
    player.physicsBody?.collisionBitMask = 0
    player.physicsBody?.contactTestBitMask = PhysicsCategory.CoinNormal | PhysicsCategory.CoinSpecial
    player.zPosition = ForegroundZ.Player.rawValue
    
    playerTrail = setupTrail("PlayerTrail")
    
    animJump = setupAnimWithPrefix("player01_jump_", start: 1, end: 4, timePerFrame: 0.1)
    animFall = setupAnimWithPrefix("player01_fall_", start: 1, end: 3, timePerFrame: 0.1)
    animSteerLeft = setupAnimWithPrefix("player01_steerleft_", start: 1, end: 2, timePerFrame: 0.1)
    animSteerRight = setupAnimWithPrefix("player01_steerright_", start: 1, end: 2, timePerFrame: 0.1)
    
    fgNode.addChild(player)
  }
  
  func setupLevel() {
  
    title.position = CGPoint(x: size.width/2, y: size.height * 0.7)
    worldNode.addChild(title)
    
  }
  
  func setupLava() {
    if true {
      lava = SKEmitterNode(fileNamed: "Lava")
    } else {
      lava = SKSpriteNode(color: SKColorWithRGB(255, 134, 16), size:CGSize(width: 320, height: 150))
    }
    lava.zPosition = ForegroundZ.Lava.rawValue
    lava.position = CGPoint(x:size.width/2, y:-300)
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
  
    gameState = .WaitingForBomb
    
    SKTAudio.sharedInstance().pauseBackgroundMusic()
    
    title.runAction(SKAction.scaleTo(0, duration: 0.5))
    
    soundManager.playSoundBombDrop()
    soundManager.playSoundTickTock()
    
    bomb.position = CGPoint(x: player.position.x, y: player.position.y)
    bomb.zPosition = ForegroundZ.Bomb.rawValue
    fgNode.addChild(bomb)
    
    let scaleUp = SKAction.scaleTo(1.25, duration: 0.25)
    scaleUp.timingMode = .EaseInEaseOut
    let scaleDown = SKAction.scaleTo(1.0, duration: 0.25)
    scaleDown.timingMode = .EaseInEaseOut
    bomb.runAction(SKAction.repeatActionForever(
      SKAction.sequence([scaleUp, scaleDown])
    ))
    
    bomb.runAction(SKAction.sequence([
      SKAction.waitForDuration(2.0),
      SKAction.runBlock(switchToPlaying)
    ]))
  
  }
  
  func switchToPlaying() {
  
    gameState = .Playing
  
    soundManager.playMusicAction()    
    
    let emitter = SKEmitterNode(fileNamed: "BigExplosion")
    emitter.position = bomb.position
    fgNode.addChild(emitter)
    emitter.runAction(SKAction.removeFromParentAfterDelay(2.0))
    
    player.physicsBody!.dynamic = true
    soundManager.playSoundSuperBoost()
    superBoostPlayer()
  
  }
  
  func switchToGameOver() {
  
    gameState = .GameOver
    
    // Turn off physics
    physicsWorld.contactDelegate = nil
    player.physicsBody?.dynamic = false
    
    // Turn off player trail
    removeTrail(playerTrail)
    
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
  
  // MARK: Game Objects
  
  
  // MARK: Level Spawning
  
    
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
      updateVisible()
      bgNode.update()
      mgNode.update()
      level.update()

      updatePlayer()
      updateLava()
      updateCollisionLava()
      updateRedAlert()
      
      updateExplosionsWithLowRange(0.1, highRange:0.5, scaleFactor: 1.0)
    }
  }
  
  func updateCamera() {
  
    let target = player.position
    var targetPosition = CGPoint(x: worldNode.position.x, y: -(target.y - size.height * 0.4))
    targetPosition.y = min(targetPosition.y, -(lava.position.y))
    var newPosition = targetPosition
    
    // Lerp camera
    let diff = targetPosition - fgNode.position
    let lerpValue = CGFloat(0.05)
    let lerpDiff = diff * lerpValue
    newPosition = fgNode.position + lerpDiff
    
    self.fgNode.position = newPosition
    self.mgNode.position = CGPoint(x: newPosition.x/5.0, y: newPosition.y/5.0)
    self.bgNode.position = CGPoint(x: newPosition.x/10.0, y: newPosition.y/10.0)
    
  }
  
  func updateVisible() {

    let lowerLeft = CGPoint(x: 0, y: 0)
    let upperLeft = CGPoint(x: 0, y: size.height)

    visibleMinYFg = convertPoint(lowerLeft, toNode: fgNode).y
    visibleMaxYFg = convertPoint(upperLeft, toNode: fgNode).y

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
    
    // Set animation appropriately
    if player.physicsBody?.velocity.dy < 0 {
      runAnim(animFall)
    } else {
      if abs(player.physicsBody!.velocity.dx) > 100.0 {
        if (player.physicsBody!.velocity.dx > 0) {
          runAnim(animSteerRight)
        } else {
          runAnim(animSteerLeft)
        }
      } else {
        runAnim(animJump)
      }
    }
  
  }
  
  func updateLava() {
    
    let lavaVelocity = CGPoint(x: 0, y: 120)
    let lavaStep = lavaVelocity * CGFloat(dt)
    var newPosition = lava.position + lavaStep
    
    newPosition.y = max(newPosition.y, visibleMinYFg - 25.0)
    lava.position = newPosition
    
  }
  
  func updateCollisionLava() {
    
    if player.position.y < lava.position.y + 90 {
    
      hitLava()
    
      lives--
      if lives <= 0 {
        switchToGameOver()
      }
      
    }
  }
  
  func updateRedAlert() {
  
    let amt: CGFloat = CGFloat(lastUpdateTime) * π * 2.0 / 1.93725
    let colorBlendFactor = (sin(amt) + 1.0) / 2.0
    
    for container in bgNode.children {
      for node in container.children {
        if let sprite = node as? SKSpriteNode {
          sprite.color = SKColorWithRGB(255, 0, 0)
          sprite.colorBlendFactor = colorBlendFactor
        }
      }
    }
    
    for container in mgNode.children {
      for node in container.children {
        if let sprite = node as? SKSpriteNode {
          sprite.color = SKColorWithRGB(255, 0, 0)
          sprite.colorBlendFactor = colorBlendFactor
        }
      }
    }
  
  }
  
  func updateExplosionsWithLowRange(lowRange: CGFloat, highRange: CGFloat, scaleFactor: CGFloat) {
  
    timeSinceLastExplosion += CGFloat(dt)
    if timeSinceLastExplosion > timeForNextExplosion {
    
      timeForNextExplosion = CGFloat.random(min: lowRange, max: highRange)
      timeSinceLastExplosion = 0
      
      let screenPos = CGPoint(x: CGFloat.random(min: 0, max: size.width), y: CGFloat.random(min: size.height * -0.1, max: size.height * 1.1))
      createRandomExplosionAtPos(screenPos, scaleFactor: scaleFactor)
    
    }
  
  }
  
  // MARK: Special effects
  
  func removeTrail(trail: SKEmitterNode) {
    trail.numParticlesToEmit = 1
    trail.runAction(SKAction.removeFromParentAfterDelay(1.0))
  }
  
  func setupTrail(name: String) -> SKEmitterNode {
    let trail = SKEmitterNode(fileNamed: name)
    trail.targetNode = fgNode
    player.addChild(trail)
    return trail
  }
  
  func hitLava() {
  
    soundManager.playSoundHitLava()
    boostPlayer()
    screenShakeByAmt(50)
    
    let smokeTrail = setupTrail("SmokeTrail")
    runAction(SKAction.sequence([
      SKAction.waitForDuration(3.0),
      SKAction.runBlock() {
        self.removeTrail(smokeTrail)
      }
    ]))
  
  }
  
  func setupAnimWithPrefix(prefix: String, start: Int, end: Int, timePerFrame: NSTimeInterval) -> SKAction {
  
    var textures = [SKTexture]()
    for i in start..<end {
      textures.append(SKTexture(imageNamed: "\(prefix)\(i)"))
    }
    return SKAction.animateWithTextures(textures, timePerFrame: timePerFrame)
  
  }
  
  func runAnim(anim: SKAction) {
    if curAnim == nil || curAnim! != anim {
      player.removeActionForKey("anim")
      player.runAction(anim, withKey: "anim")
      curAnim = anim
    }
  }
  
  func createRandomExplosionAtPos(pos: CGPoint, scaleFactor: CGFloat) {
    
    let randomNum = Int.random(soundManager.soundExplosions.count)
    soundManager.playSoundExplosion(randomNum)
    
    let explosion = SKEmitterNode(fileNamed: "ColoredExplosion")
    explosion.position = convertPoint(pos, toNode:self.mgNode)
    explosion.particleScale = ((CGFloat(randomNum) + 1) / 2) * scaleFactor
    mgNode.addChild(explosion)
    
    explosion.runAction(SKAction.removeFromParentAfterDelay(1.0))
    
    if (Int.random(soundManager.soundExplosions.count) == 0) {
      screenShakeByAmt(4.0 * CGFloat(randomNum) * scaleFactor)
    }
    
  }
  
  func screenShakeByAmt(amt: CGFloat) {
    worldNode.position = CGPointZero
    worldNode.removeActionForKey("shake")
    
    let amount = CGPointMake(0, -amt)
    let action = SKAction.screenShakeWithNode(worldNode, amount: amount, oscillations: 10, duration: 2.0)
    worldNode.runAction(action, withKey: "shake")
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
  
  func scrollTo(position:CGPoint) {
    fgNode.position = position
    mgNode.position = position / 5.0
    bgNode.position = position / 10.0
  }
  
  func setPlayerVelocity(amount:CGFloat) {
    player.physicsBody!.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: max(player.physicsBody!.velocity.dy, amount))
  }
  
  func jumpPlayer() {
    setPlayerVelocity(650)
  }
  
  func boostPlayer() {
    setPlayerVelocity(1000)
    screenShakeByAmt(20)
  }
  
  func superBoostPlayer() {
    setPlayerVelocity(1500)
    screenShakeByAmt(100)
  }
 
}
