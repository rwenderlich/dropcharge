//
//  RepeatableNode.swift
//  DropCharge
//
//  Created by Main Account on 11/28/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import SpriteKit

class RepeatableNode: SKNode {

  init(prefix:String, number:Int, containerSize:CGSize) {
    super.init()

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
      addChild(container)
      
      // Increment y offset
      yOffset += containerSize.height
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func update() {
  
    let bottomLeft = CGPoint(x: 0, y: 0)
    let visibleMinY = scene!.convertPoint(bottomLeft, toNode: self).y
    
    for node in children {
      if let container = node as? SKSpriteNode {
        if container.position.y + container.size.height/2 < visibleMinY {
          let newPosition = CGPoint(x: container.position.x, y: container.position.y + (container.size.height * CGFloat(children.count)))
          container.position = newPosition
        }
      }
    }
  }

}