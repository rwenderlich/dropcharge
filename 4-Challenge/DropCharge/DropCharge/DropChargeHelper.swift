//
//  DropChargeHelper.swift
//  DropCharge
//
//  Created by Main Account on 11/23/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import SpriteKit

class DropChargeHelper {

  func setupBgNode(scene: SKScene, bgNode: SKNode) {
    setupRepeatable(bgNode, prefix: "bg_", number: 3, containerSize: CGSize(width: scene.size.width, height: scene.size.height))
  }
  
  func setupMgNode(scene: SKScene, mgNode: SKNode) {
    setupRepeatable(mgNode, prefix: "midground_", number: 4, containerSize: CGSize(width: scene.size.width, height: scene.size.height))
  }
  
  func updateBgNode(scene: SKScene, bgNode: SKNode) {
    updateRepeatable(scene, parentNode: bgNode)
  }
  
  func updateMgNode(scene: SKScene, mgNode: SKNode) {
    updateRepeatable(scene, parentNode: mgNode)
  }

  // MARK: Helpers

  private func setupRepeatable(parentNode: SKNode, prefix:String, number:Int, containerSize:CGSize) {
    var yOffset = containerSize.height/2
    for i in 1...number {
      
      // Create sprite
      let sprite = SKSpriteNode(imageNamed: "\(prefix)\(i)")
      sprite.position = CGPointZero
      
      // Create container
      let container = SKSpriteNode()
      container.size = containerSize
      container.position = CGPoint(x: containerSize.width/2, y: yOffset)
      container.addChild(sprite)
      parentNode.addChild(container)
      
      // Increment y offset
      yOffset += containerSize.height
    }
  }

  private func updateRepeatable(scene: SKScene, parentNode: SKNode) {
  
    let bottomLeft = CGPoint(x: 0, y: 0)
    let visibleMinY = scene.convertPoint(bottomLeft, toNode: parentNode).y
    
    for node in parentNode.children {
      if let container = node as? SKSpriteNode {
        if container.position.y + container.size.height/2 < visibleMinY {
          let newPosition = CGPoint(x: container.position.x, y: container.position.y + (container.size.height * CGFloat(parentNode.children.count)))
          container.position = newPosition
        }
      }
    }
  }

}