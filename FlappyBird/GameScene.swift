//
//  GameScene.swift
//  FlappyBird
//
//  Created by 井上真悠子 on 2020/05/11.
//  Copyright © 2020 taro.kirameki. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var Apple:SKNode!
    
    let birdCategory:UInt32 = 1 << 0
    let groundCategory:UInt32 = 1 << 1
    let wallCategory:UInt32 = 1 << 2
    let scoreCategory:UInt32 = 1 << 3
    let appleCategory:UInt32 = 1 << 4//appleの衝突判定カテゴリー
    
    var score = 0
    var itemscore = 0// アイテムスコアを設定
    
    var player:AVAudioPlayer?
    
    let userDefaults:UserDefaults = UserDefaults.standard
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    
    
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx:0,dy:-4)
        
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red:0.15,green:0.75,blue:0.90,alpha:1)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        Apple = SKNode()
        scrollNode.addChild(Apple)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setApple()
        
        setupScoreLabel()
        
        
        
        
    }
    
    func setupGround() {
        
        let groundTexture = SKTexture(imageNamed:"ground")
        groundTexture.filteringMode = .nearest
        
        let needNumber = Int(self.frame.size.width/groundTexture.size().width)+2
       
        let moveGround = SKAction.moveBy(x:-groundTexture.size().width,y:0,duration: 5)
        let resetGround = SKAction.moveBy(x:groundTexture.size().width,y:0,duration: 0)
        
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture:groundTexture)
            
            sprite.position = CGPoint(
                x:groundTexture.size().width/2+groundTexture.size().width*CGFloat(i),
                y:groundTexture.size().height/2
            )
            
            sprite.run(repeatScrollGround)
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            sprite.physicsBody?.isDynamic = false
            
            sprite.physicsBody?.categoryBitMask = groundCategory
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupCloud() {
        
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width/cloudTexture.size().width)+2
        
        let moveCloud = SKAction.moveBy(x:-cloudTexture.size().width,y:0,duration:20)
        let resetCloud = SKAction.moveBy(x:cloudTexture.size().width,y:0,duration:0)
        
        let repeatCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture:cloudTexture)
            sprite.zPosition = -100
            sprite.position = CGPoint(
                x:cloudTexture.size().width/2 + cloudTexture.size().width*CGFloat(i),
                y:self.size.height - cloudTexture.size().height/2
            )
            sprite.run(repeatCloud)
            
            
            
            scrollNode.addChild(sprite)
            
        
        }
        
        
    }
    
    func setupWall() {
        
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        let moveWall = SKAction.moveBy(x:-movingDistance,y:0,duration: 4)
        
        let removeWall = SKAction.removeFromParent()
        
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        let slit_length = birdSize.height*3
        
        let random_y_range = birdSize.height * 3
        
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height+(self.frame.size.height-groundSize.height)/2
        let under_wall_lowest_y = center_y - slit_length/2-wallTexture.size().height/2-random_y_range/2
        
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x:self.frame.size.width + wallTexture.size().width/2,y:0)
            wall.zPosition = -50
            
            let radom_y = CGFloat.random(in :0..<random_y_range)
            
            let under_wall_y = under_wall_lowest_y + radom_y
            
            let under = SKSpriteNode(texture:wallTexture)
            under.position = CGPoint(x:0,y:under_wall_y)
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask=self.wallCategory
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            let upper = SKSpriteNode(texture:wallTexture)
            upper.position = CGPoint(x:0,y:under_wall_y + wallTexture.size().height + slit_length)
            upper.physicsBody = SKPhysicsBody(rectangleOf:wallTexture.size())
            upper.physicsBody?.categoryBitMask=self.wallCategory
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x:upper.size.width+birdSize.width/2,y:self.frame.height/2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf:CGSize(width:upper.size.width,height:self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed:"bird_b")
        birdTextureB.filteringMode = .linear
        
        let textureAnimation = SKAction.animate(with:[birdTextureA,birdTextureB],timePerFrame: 0.2)
        
        let flap = SKAction.repeatForever(textureAnimation)
        
        bird = SKSpriteNode(texture:birdTextureA)
        bird.position = CGPoint(x:self.frame.size.width * 0.2,y:self.frame.size.height*0.7)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        bird.run(flap)
        
        addChild(bird)
    }
    
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero
            
            bird.physicsBody?.applyImpulse(CGVector(dx:0,dy:15))
            
        } else if bird.speed == 0{
            restart()
        }
        
        
        
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
   
        
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory    {
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            var bestScore = userDefaults.integer(forKey:"BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore,forKey:"BEST")
                userDefaults.synchronize()
                
            }
        } else if (contact.bodyA.categoryBitMask & appleCategory) == appleCategory || (contact.bodyB.categoryBitMask & appleCategory) == appleCategory {
            
            print("ItemScoreUP")
            itemscore += 1
            
            if (contact.bodyA.categoryBitMask & appleCategory) == appleCategory  {
                // 再生データの作成.
                let sound = NSDataAsset(name: "pon")
                player = try? AVAudioPlayer(data: sound!.data)
                player?.play() //これで音が鳴る
                contact.bodyA.node?.removeFromParent()//衝突したappleを消す
            } else {
                
                // 再生データの作成
                let sound = NSDataAsset(name: "pon")
                player = try? AVAudioPlayer(data: sound!.data)
                player?.play() //これで音が鳴る
                
                contact.bodyB.node?.removeFromParent()
            }
            itemScoreLabelNode.text = "ItemScore:\(itemscore)"//現在のitemscoreを更新
            
            
        } else {
            print("GameOver")
            
            scrollNode.speed = 0
            print("OK")
            print(scrollNode.speed)
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle:CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01,duration:1)
            
            bird.run(roll,completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        itemscore = 0//itemscoreを0に初期化
        itemScoreLabelNode.text = "ItemScore:\(itemscore)"
        
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        
        bird.position = CGPoint(x:self.frame.size.width * 0.2,y:self.size.height*0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x:10,y:self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x:10,y:self.frame.size.height - 90)
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        
        itemscore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x:10,y:self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ItemScore:\(itemscore)"
        self.addChild(itemScoreLabelNode)
    }
    
    func setApple() {
        
        
        let createAppleAnimation = SKAction.run({
            
          
            
            let appleTexture = SKTexture(imageNamed:"apple")
            appleTexture.filteringMode = .linear//りんごの画像を読み込む
            
            let wallTexture = SKTexture(imageNamed: "wall")
            let movingDistancea = CGFloat(self.frame.size.width + wallTexture.size().width)//りんごが動く距離
            
            let moveApple = SKAction.moveBy(x:-movingDistancea,y:0,duration: 4)//画面外まで移動
            let removeApple = SKAction.removeFromParent()//自身を取り除く
            let appleAnimation = SKAction.sequence([moveApple,removeApple])//画面外まで移動して自身を取り除くアクション
            
            
            let apple = SKSpriteNode(texture:appleTexture)
            apple.zPosition = -30
            
            let groundSize = SKTexture(imageNamed: "ground").size()
            
            let random_ay = CGFloat.random(in :groundSize.height*5/4..<self.frame.size.height*4/5)//appleのy座標をランダムに指定
            
            apple.xScale = 0.05//appleの大きさを10分の1にする
            apple.yScale = 0.05//appleの大きさを10分の1にする
            
            apple.position = CGPoint(x:self.frame.size.width + wallTexture.size().width/2-movingDistancea/4,y:random_ay)//appleの位置を決める
            apple.zPosition = -30
            
            apple.run(appleAnimation)//actionをappleにつける
            apple.physicsBody = SKPhysicsBody(circleOfRadius: apple.size.height / 2)//appleに物理演算を追加する
            apple.physicsBody?.isDynamic = false
            apple.physicsBody?.categoryBitMask = self.appleCategory//自身のカテゴリーを追加
            apple.physicsBody?.contactTestBitMask = self.birdCategory//鳥との衝突を検知
            
            
            
           
            
            self.Apple.addChild(apple)//appleをAppleの子供にする
        })
        
        let waitAnimationa = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimationa = SKAction.repeatForever(SKAction.sequence([createAppleAnimation,waitAnimationa]))
        
        
        
        Apple.run(repeatForeverAnimationa)
        
    }

}
