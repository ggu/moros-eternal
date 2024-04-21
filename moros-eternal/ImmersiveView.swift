//
//  ImmersiveView.swift
//  moros-eternal
//
//  Created by Gabriel Uribe on 4/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

var contentView: RealityViewContent?
var environmentResource: EnvironmentResource?

let enemies: CollisionGroup = CollisionGroup(rawValue: 1 << 0)
let spells: CollisionGroup = CollisionGroup(rawValue: 1 << 1)

struct ImmersiveView: View {
	var contentEntity = Entity()
	@State private var collisionSubscription: EventSubscription?
	@State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        RealityView { content in
			contentView = content
			
			collisionSubscription = content.subscribe(to: CollisionEvents.Began.self, on: nil, componentType: nil) { event in
//				print("Collision detected between \(event.entityA) and \(event.entityB)")
				
				if (event.entityA.name == "SPELL" && event.entityB.name == "ENEMY") {
					event.entityA.removeFromParent()
					event.entityB.removeFromParent()
				} else if (event.entityA.name == "ENEMY" && event.entityB.name == "SPELL") {
					event.entityA.removeFromParent()
					event.entityB.removeFromParent()
				}
			}
			
			// A 20m box that receives hits.
			let collisionBox = makeCollisionBox(size: 30)
			
			content.add(collisionBox)
			
			guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { return }
			environmentResource = resource
			
//
			// Put skybox here.  See example in World project available at
			// https://developer.apple.com/
        }
		.gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
			let location3D = value.convert(value.location3D, from: .local, to: .scene)
			addCube(tapLocation: location3D)
		})
		.onReceive(timer) { _ in
			
			if true { // !gameModel.isPaused
				Task { @MainActor () -> Void in
					do {
						let spawnAmount = 1
						spawnEnemy(environmentResource!)
//						for _ in (0..<spawnAmount) {
//							spawnEnemy(environmentResource!)
//							try await Task.sleep(for: .milliseconds(5000))
//						}
					} catch {
						print("Error spawning an enemy:", error)
					}
						
				}
			}
//				else if gameModel.timeLeft == 0 {
//					print("Game finished.")
//					gameModel.isFinished = true
//					gameModel.timeLeft = -1
//				}
			
		}
    }
	
	func spawnEnemy(_ resource: EnvironmentResource) {
		
		let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
		
		let enemy = ModelEntity(mesh: .generateBox(size: [0.5,0.5,0.5]), materials: [SimpleMaterial(color: .red, isMetallic: false)])
		enemy.components.set(iblComponent)
		enemy.components.set(ImageBasedLightReceiverComponent(imageBasedLight: enemy))
		enemy.collision = CollisionComponent(shapes: [.generateBox(size: [0.6, 0.6, 0.6])])
		enemy.collision?.filter.group = enemies
		enemy.collision?.filter.mask = spells
		enemy.name = "ENEMY"
		
		let start = Point3D(
			x: enemyPaths[enemyPathsIndex].0,
			y: enemyPaths[enemyPathsIndex].1,
			z: enemyPaths[enemyPathsIndex].2
		)
		enemy.position = simd_float(start.vector + .init(x: 0, y: 0, z: -0.7))
		contentView!.add(enemy)
		
		enemyPathsIndex += 1
		enemyPathsIndex %= enemyPaths.count
		
		let end = Point3D(x: 0, y: 0, z: 0)
		let line = FromToByAnimation<Transform>(
			name: "line",
			from: .init(scale: .init(repeating: 1), translation: simd_float(start.vector)),
			to: .init(scale: .init(repeating: 1), translation: simd_float(end.vector)),
			duration: EnemySpawnParameters.speed,
			bindTarget: .transform
		)
		
		let animation = try! AnimationResource
			.generate(with: line)
		
		enemy.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
	}
	
	func addCube(tapLocation: SIMD3<Float>) {
//		let placementLocation = tapLocation + SIMD3<Float>(0, 0.2, 0)
		let placementLocation = SIMD3<Float>(0, 1.0, 0)
		let finalLocation = tapLocation + SIMD3<Float>(0, 0, -1)

		
		let iblComponent = ImageBasedLightComponent(source: .single(environmentResource!), intensityExponent: 0.25)

		let spell = ModelEntity(mesh: .generateBox(size: [0.1,0.1,0.1]), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
		spell.components.set(iblComponent)
		spell.components.set(ImageBasedLightReceiverComponent(imageBasedLight: spell))
		spell.name = "SPELL"

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
		
		let animation = try! AnimationResource
			.generate(with: line)
		
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
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.094_368_331_589_704),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.254_713_426_424_875),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.601_541_438_900_849),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.183_621_312_117_454),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.010_893_563_433_282),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.680_206_361_333_17),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.383_548_882_448_866),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.169_154_476_151_876),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.147_229_496_720_969),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.051_132_737_691_349),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.503_837_407_474_947),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.760_994_300_660_705),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.908_048_018_555_112),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -7.525_853_388_894_509),
	(x: Double.random(in: -2...2), y: Double.random(in: -2...2), z: -8.164_641_191_459_626)]


#Preview(immersionStyle: .full) {
    ImmersiveView()
}
