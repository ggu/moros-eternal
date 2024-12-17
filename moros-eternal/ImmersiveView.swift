//
//  ImmersiveView.swift
//  moros-eternal
//
//  Created by Gabriel Uribe on 4/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFAudio

var contentView: RealityViewContent?
var environmentResource: EnvironmentResource?

let enemies: CollisionGroup = CollisionGroup(rawValue: 1 << 0)
let spells: CollisionGroup = CollisionGroup(rawValue: 1 << 1)

var enemyEntities: [Entity] = []
var currentOrb: ChaoticOrb? = nil

var isGameOver = false

var score = 0

var enemyTemplate: Entity? = nil
var spellTemplate: Entity? = nil
var impactTemplate: Entity? = nil
var frostboltTemplate: Entity? = nil

var enemyAnimation: AnimationResource?

var spellSound: AudioFileResource?
var enemyHitSound: AudioFileResource?
var frostboltSound: AudioFileResource?

var timeElapsed = 0
var difficultyMultiplier = 1.0

struct ImmersiveView: View {
    @State private var collisionSubscription: EventSubscription?
    @State private var animationSubscription: EventSubscription?

    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        RealityView { content in
            contentView = content
            
            animationSubscription = content.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: nil, componentType: nil) { event in
                if let entity = event.playbackController.entity, entity.name.hasPrefix("ENEMY") {
                    // Game over sequence
                    if (!isGameOver) {
                        openWindow(id: "GameOverView")
                    }
                    let highScore = UserDefaults.standard.integer(forKey: "highestScore")
                    if (highScore < score) {
                        UserDefaults.standard.set(score, forKey: "highestScore")
                    }
                    isGameOver = true
                    entity.removeFromParent()
                    let index = enemyEntities.firstIndex { entity2 in
                        entity.name == "ENEMY" + String(entity.id)
                    }
                    enemyEntities.remove(at: index!)
                } else if let entity = event.playbackController.entity, entity.name.hasPrefix("SPELL") || entity.name.hasPrefix("FROSTBOLT") {
                    entity.removeFromParent()
                }
            }
            collisionSubscription = content.subscribe(to: CollisionEvents.Began.self, on: nil, componentType: nil) { event in
                //                print("Collision detected between \(event.entityA) and \(event.entityB)")
                
                if (event.entityA.name == "SPELL" && (event.entityB.name.hasPrefix("ENEMY") || event.entityB.name == "CHAOTIC_ORB")) {
                    score += 1
                    event.entityA.removeFromParent()
                    
                    if event.entityB.name == "CHAOTIC_ORB" {
                        print("Spell hit chaotic orb - destroying orb")
                        ChaoticOrb.isDestroyed = true
                    }
                    
                    event.entityB.removeFromParent()
                    
                    if event.entityB.name.hasPrefix("ENEMY") {
                        // Only remove from array if the enemy still exists in it
                        if let index = enemyEntities.firstIndex(where: { entity in
                            entity.name == event.entityB.name
                        }) {
                            print("Removing enemy at index \(index)")
                            enemyEntities.remove(at: index)
                            // Call ChaoticOrb's handleDragonKill when an enemy is destroyed
                            if let content = contentView {
                                ChaoticOrb.handleDragonKill(contentView: content)
                            }
                        }
                    }
                    
                    if let impact = impactTemplate?.clone(recursive: true) {
                        impact.setPosition(event.entityB.position(relativeTo: nil), relativeTo: nil)
                        contentView!.add(impact)
                        if let enemyHitSoundLoaded = enemyHitSound {
                            let audioController = impact.prepareAudio(enemyHitSoundLoaded)
                            audioController.gain = 30
                            audioController.play()
                        }
                    }
                    
                } else if ((event.entityA.name.hasPrefix("ENEMY") || event.entityA.name == "CHAOTIC_ORB") && event.entityB.name == "SPELL") {
                    score += 1
                    
                    if event.entityA.name == "CHAOTIC_ORB" {
                        print("Spell hit chaotic orb - destroying orb")
                        ChaoticOrb.isDestroyed = true
                    }
                    
                    event.entityA.removeFromParent()
                    event.entityB.removeFromParent()
                    
                    if event.entityA.name.hasPrefix("ENEMY") {
                        // Only remove from array if the enemy still exists in it
                        if let index = enemyEntities.firstIndex(where: { entity in
                            entity.name == event.entityA.name
                        }) {
                            print("Removing enemy at index \(index)")
                            enemyEntities.remove(at: index)
                            // Call ChaoticOrb's handleDragonKill when an enemy is destroyed
                            if let content = contentView {
                                ChaoticOrb.handleDragonKill(contentView: content)
                            }
                        }
                    }
                    
                    if let impact = impactTemplate?.clone(recursive: true) {
                        impact.setPosition(event.entityA.position(relativeTo: nil), relativeTo: nil)
                        contentView!.add(impact)
                        if let enemyHitSoundLoaded = enemyHitSound {
                            let audioController = impact.prepareAudio(enemyHitSoundLoaded)
                            audioController.gain = 30
                            audioController.play()
                        }
                    }
                } else if (event.entityA.name == "FROSTBOLT" && (event.entityB.name.hasPrefix("ENEMY") || event.entityB.name == "CHAOTIC_ORB")) {
                    print("Frostbolt detected in collision with: \(event.entityB.name)")
                    print("Frostbolt hit an enemy or chaotic orb")
                    score += 1
                    
                    if event.entityB.name == "CHAOTIC_ORB" {
                        ChaoticOrb.isDestroyed = true
                        event.entityB.removeFromParent()
                    } else if event.entityB.name.hasPrefix("ENEMY") {
                        // Only remove from array if the enemy still exists in it
                        if let index = enemyEntities.firstIndex(where: { entity in
                            entity.name == event.entityB.name
                        }) {
                            print("Removing enemy at index \(index)")
                            enemyEntities.remove(at: index)
                            event.entityB.removeFromParent()
                            // Call ChaoticOrb's handleDragonKill when an enemy is destroyed
                            if let content = contentView {
                                ChaoticOrb.handleDragonKill(contentView: content)
                            }
                        }
                    }
                    
                    if let impact = impactTemplate?.clone(recursive: true) {
                        impact.setPosition(event.entityB.position(relativeTo: nil), relativeTo: nil)
                        contentView!.add(impact)
                        if let enemyHitSoundLoaded = enemyHitSound {
                            let audioController = impact.prepareAudio(enemyHitSoundLoaded)
                            audioController.gain = 30
                            audioController.play()
                        }
                    }
                } else if ((event.entityA.name.hasPrefix("ENEMY") || event.entityA.name == "CHAOTIC_ORB") && event.entityB.name == "FROSTBOLT") {
                    print("Frostbolt detected in collision with: \(event.entityA.name)")
                    print("Frostbolt hit an enemy or chaotic orb")
                    score += 1
                    
                    if event.entityA.name == "CHAOTIC_ORB" {
                        print("Frostbolt hit chaotic orb - destroying orb")
                        ChaoticOrb.isDestroyed = true
                        event.entityA.removeFromParent()
                    } else if event.entityA.name.hasPrefix("ENEMY") {
                        // Only remove from array if the enemy still exists in it
                        if let index = enemyEntities.firstIndex(where: { entity in
                            entity.name == event.entityA.name
                        }) {
                            print("Removing enemy at index \(index)")
                            enemyEntities.remove(at: index)
                            event.entityA.removeFromParent()
                            // Call ChaoticOrb's handleDragonKill when an enemy is destroyed
                            if let content = contentView {
                                ChaoticOrb.handleDragonKill(contentView: content)
                            }
                        }
                    }
                    
                    if let impact = impactTemplate?.clone(recursive: true) {
                        impact.setPosition(event.entityA.position(relativeTo: nil), relativeTo: nil)
                        contentView!.add(impact)
                        if let enemyHitSoundLoaded = enemyHitSound {
                            let audioController = impact.prepareAudio(enemyHitSoundLoaded)
                            audioController.gain = 30
                            audioController.play()
                        }
                    }
                }
            }
            
            initializeAssets()
            
            // A 20m box that receives hits.
            let collisionBox = makeCollisionBox(size: 30)
            
            content.add(collisionBox)
            
            guard let resource = try? await EnvironmentResource(named: "ImageBasedLighting") else { return }
            environmentResource = resource
            
            //
            // Put skybox here.  See example in World project available at
            // https://developer.apple.com/
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            let location3D = value.convert(value.location3D, from: .local, to: .scene)
            castSpell(tapLocation: location3D)
        })
        .onReceive(timer) { _ in
            if true { // !gameModel.isPaused
                Task { @MainActor () -> Void in
                    do {
                        timeElapsed += 1
                        
                        // Increase difficulty multiplier over time
                        difficultyMultiplier = min(3.0, 1.0 + Double(timeElapsed) / 60.0)
                        
                        if (timeElapsed % 3 == 0) { 
                            let spawnAmount = Int(ceil(Double(timeElapsed) / 30.0 * difficultyMultiplier)) 
                            guard let resource = environmentResource else { return }
                            for _ in (0..<spawnAmount) {
                                spawnEnemy(environmentResource!)
                                try await Task.sleep(for: .milliseconds(300)) 
                            }
                            spawnEnemy(resource)
                        }
                    }
                }
            }
        }
    }
    
    static var audioPlayer: AVAudioPlayer?
    
    static func playBackgroundMusic() {
        if let audioPlayer = audioPlayer {
            if !audioPlayer.isPlaying {
                audioPlayer.play()
            }
        } else {
            let path = Bundle.main.path(forResource: "music", ofType: "mp3")!
            let url = URL(fileURLWithPath: path)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 0.5
                audioPlayer?.play()
                
            } catch {
                print ("Audio code issue")
                
            }
        }
    }
    
    /// Preload assets when the app launches to avoid pop-in during the game.
    func initializeAssets() {		
		enemyTemplate = try! Entity.load(named: "WyvernDragon_flying_decimated_2.usdz")

		enemyTemplate!.setScale(.init(repeating: 0.05), relativeTo: nil)
		
		guard !enemyTemplate!.availableAnimations.isEmpty else {
			print("No animations found in the model!")
			return
		}
		
		let def = enemyTemplate!.availableAnimations[1].definition
		enemyAnimation = try! AnimationResource.generate(with: AnimationView(
			source: def,
			trimStart: 0.0,
			trimEnd: 2.0  
		))
		
		let skybox = try! Entity.load(named: "Skybox.usda", in: realityKitContentBundle)
		skybox.setScale(SIMD3<Float>(repeating: 10), relativeTo: nil)
		contentView!.add(skybox)
		
		spellTemplate = try! Entity.load(named: "Spell.usda", in: realityKitContentBundle)
		impactTemplate = try! Entity.load(named: "Impact.usda", in: realityKitContentBundle)
		frostboltTemplate = try! Entity.load(named: "Frostbolt.usda", in: realityKitContentBundle)
		print("Frostbolt template loaded successfully")
		
		ImmersiveView.playBackgroundMusic()
		
		Task {
			spellSound = try await AudioFileResource(named: "FireballSound.wav")
			enemyHitSound = try await AudioFileResource(named: "EnemyDeath.mp3")
			frostboltSound = try await AudioFileResource(named: "Frostbolt.mp3")
		}
	}
    
    func spawnEnemy(_ resource: EnvironmentResource) {
        
        let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
        let entity = enemyTemplate!.clone(recursive: true)
        entity.position = simd_float([0, -1, 0])
        
        // Rotate the dragon 180 degrees around the Y axis to face the player
        entity.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0.5])
        
        entity.playAnimation(enemyAnimation!.repeat(count: 100))
        
        let enemy = ModelEntity()
        //let enemy = ModelEntity(mesh: .generateBox(size: simd_float3(1.0, 0.5, 1.0)))
        enemy.addChild(entity)
        enemy.components.set(iblComponent)
        enemy.components.set(ImageBasedLightReceiverComponent(imageBasedLight: enemy))
        enemy.collision = CollisionComponent(shapes: [.generateBox(size: .init(repeating: 2.0))])
        enemy.collision?.filter.group = enemies
        enemy.collision?.filter.mask = spells
        enemy.name = "ENEMY" + String(enemy.id)
        
        let start = Point3D(
            x: enemyPaths[enemyPathsIndex].0,
            y: enemyPaths[enemyPathsIndex].1,
            z: enemyPaths[enemyPathsIndex].2
        )
        enemy.position = simd_float(start.vector + .init(x: 0, y: 0, z: -0.7))
        contentView!.add(enemy)
        
        enemyPathsIndex += 1
        enemyPathsIndex %= enemyPaths.count
        
        let end = Point3D(x: 0, y: 1, z: 0)
        let line = FromToByAnimation<Transform>(
            name: "line",
            from: .init(scale: .init(repeating: 1), translation: simd_float(start.vector)),
            to: .init(scale: .init(repeating: 1), translation: simd_float(end.vector)),
            duration: EnemySpawnParameters.speed - log2(Double(timeElapsed) / 10.0), 
            bindTarget: .transform
        )
        
        let animation = try! AnimationResource
            .generate(with: line)
        
        enemy.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
        enemyEntities.append(enemy)
    }
    
    func castSpell(tapLocation: SIMD3<Float>) {
        let placementLocation = SIMD3<Float>(0, 0.8, 0.3)
        let finalLocation = tapLocation + SIMD3<Float>(0, 0, -1)
        
        let iblComponent = ImageBasedLightComponent(source: .single(environmentResource!), intensityExponent: 0.25)
        
        // Create the spell entity
        let spell = ModelEntity()
        
        if ChaoticOrb.isDestroyed {
            // FROSTBOLT
            let entity = frostboltTemplate!.clone(recursive: true)  // Using spellTemplate for now since we know it works
            entity.position = simd_float([0, 0, 0])
            spell.addChild(entity)
            spell.name = "FROSTBOLT"
            print("Frostbolt created")
            
            if let soundLoaded = frostboltSound {
                let audioController = spell.prepareAudio(soundLoaded)
                audioController.gain = 15
                audioController.play()
            }
            
            // Reset isDestroyed after creating the frostbolt
            ChaoticOrb.isDestroyed = false
            print("Reset to regular spells after frostbolt")
        } else {
            // Regular SPELL
            let entity = spellTemplate!.clone(recursive: true)
            entity.position = simd_float([0, 0, 0])
            spell.addChild(entity)
            spell.name = "SPELL"
            
            if let soundLoaded = spellSound {
                let audioController = spell.prepareAudio(soundLoaded)
                audioController.gain = 15
                audioController.play()
            }
        }
        
        spell.components.set(iblComponent)
        spell.setPosition(placementLocation, relativeTo: nil)
        spell.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])])
        spell.collision?.filter.group = spells
        spell.collision?.filter.mask = enemies
        
        contentView!.add(spell)
        
        let line = FromToByAnimation<Transform>(
            name: "line",
            from: .init(scale: .init(repeating: 1), translation: placementLocation),
            to: .init(scale: .init(repeating: 1), translation: finalLocation),
            duration: EnemySpawnParameters.speed / 10,
            bindTarget: .transform
        )
        
        let animation = try! AnimationResource.generate(with: line)
        spell.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
    }
    
    func makeCollisionBox(size: Float) -> Entity {
        
        let smallDimension: Float = 0.001
        let offset = size / 2
        
        // right face
        let right = Entity()
        right.name = "right"
        right.components.set(CollisionComponent(shapes: [.generateBox(width: smallDimension, height: size, depth: size)]))
        right.position.x = offset
        
        // left face
        let left = Entity()
        left.name = "left"
        left.components.set(CollisionComponent(shapes: [.generateBox(width: smallDimension, height: size, depth: size)]))
        left.position.x = -offset
        
        // top face
        let top = Entity()
        top.name = "top"
        top.components.set(CollisionComponent(shapes: [.generateBox(width: size, height: smallDimension, depth: size)]))
        top.position.y = offset
        
        // bottom face
        let bottom = Entity()
        bottom.name = "bottom"
        bottom.components.set(CollisionComponent(shapes: [.generateBox(width: size, height: smallDimension, depth: size)]))
        bottom.position.y = -offset
        
        // front face
        let front = Entity()
        front.name = "front"
        front.components.set(CollisionComponent(shapes: [.generateBox(width: size, height: size, depth: smallDimension)]))
        front.position.z = offset
        
        // back face
        let back = Entity()
        back.name = "back"
        back.components.set(CollisionComponent(shapes: [.generateBox(width: size, height: size, depth: smallDimension)]))
        back.position.z = -offset
        
        // All faces.
        let faces = [right, left, top, bottom, front, back]
        
        for face in faces {
            face.components.set(InputTargetComponent())
        }
        
        // parent to hold all of the entities.
        let entity = Entity()
        entity.children.append(contentsOf: faces)
        
        return entity
    }
}

/// Enemy spawn parameters (in meters).
struct EnemySpawnParameters {
    static var deltaX = 0.02
    static var deltaY = -0.12
    static var deltaZ = 12.0
    
    static var speed = 11.73 
}

/// A counter that advances to the next enemy path.
var enemyPathsIndex = 0

/// A hand-picked selection of random starting parameters for the motion of the enemies.
let enemyPaths: [(Double, Double, Double)] = [
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.094_368_331_589_704),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.254_713_426_424_875),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.601_541_438_900_849),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.183_621_312_117_454),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.010_893_563_433_282),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.680_206_361_333_17),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.383_548_882_448_866),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.169_154_476_151_876),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.147_229_496_720_969),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.051_132_737_691_349),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.503_837_407_474_947),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.760_994_300_660_705),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.908_048_018_555_112),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -7.525_853_388_894_509),
    (x: Double.random(in: -2...2), y: Double.random(in: -2...4), z: -8.164_641_191_459_626)
]

func isEqual<T: SIMD>(lhs: T, rhs: T, epsilon: T.Scalar) -> Bool where T.Scalar: FloatingPoint {
    for i in 0..<lhs.scalarCount {
        if abs(lhs[i] - rhs[i]) > epsilon {
            return false
        }
    }
    return true
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
}
