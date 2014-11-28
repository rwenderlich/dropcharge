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

class GameScene: SKScene, SKPhysicsContactDelegate {

  // MARK: Properties
  var lastUpdateTime: NSTimeInterval = 0
  var dt: NSTimeInterval = 0
  let motionManager = CMMotionManager()
  var xAcceleration = CGFloat(0)
  var gameState = GameState.WaitingForTap
  
  // MARK: Init
  override func didMoveToView(view: SKView) {
    setupLevel()
    setupNodes()
    setupPlayer()
    setupPhysics()
    setupMusic()
    setupCoreMotion()
  }

  func setupLevel() {
  }

  func setupNodes() {
  }

  func setupPlayer() {
  }

  func setupPhysics() {
  }
  
  func setupMusic() {
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
  }
  
  func switchToPlaying() {
  }
  
  // MARK: Touch Handling
  func handlePlayingTouches(touches: NSSet) {
  }
  
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    switch gameState {
      case .WaitingForTap:
        switchToWaitingForBomb()
      case .Playing:
        handlePlayingTouches(touches)
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
      // TODO      
    }
  }
  
  func updateCamera() {
  }
  
  func updatePlayer() {
  }
    
  // MARK: Contacts
  
  func didBeginContact(contact: SKPhysicsContact) {
 
    let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
    
    switch other.categoryBitMask {
      case PhysicsCategory.CoinNormal:
        if let coin = other.node as? SKSpriteNode {
          // TODO
        }
      case PhysicsCategory.CoinSpecial:
        if let coin = other.node as? SKSpriteNode {
          // TODO
        }
      case PhysicsCategory.PlatformNormal:
        if let platform = other.node as? SKSpriteNode {
          // TODO
        }
      case PhysicsCategory.PlatformBreakable:
        if let platform = other.node as? SKSpriteNode {
          // TODO
        }
      default:
      break;
    }
 
  }
  
  // MARK: Helpers
  func setPlayerVelocity(amount:CGFloat) {
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