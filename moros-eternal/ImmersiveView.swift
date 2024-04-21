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

    var body: some View {
        RealityView { content in
			contentView = content
			
			collisionSubscription = content.subscribe(to: CollisionEvents.Began.self, on: nil, componentType: nil) { event in
				print("Collision detected between \(event.entityA) and \(event.entityB)")
				
				if (event.entityA.name == "SPELL" && event.entityB.name == "ENEMY") {
					event.entityA.removeFromParent()
					event.entityB.removeFromParent()
				} else if (event.entityA.name == "ENEMY" && event.entityB.name == "SPELL") {
					event.entityA.removeFromParent()
					event.entityB.removeFromParent()
				}
			}
			
			// A 20m box that receives hits.
			let collisionBox = makeCollisionBox(size: 20)
			
			content.add(collisionBox)
			
			guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { return }
			environmentResource = resource
			let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
			
			let enemy = ModelEntity(mesh: .generateBox(size: [1,1,1]), materials: [SimpleMaterial(color: .red, isMetallic: false)])
			enemy.components.set(iblComponent)
			enemy.components.set(ImageBasedLightReceiverComponent(imageBasedLight: enemy))
			enemy.collision = CollisionComponent(shapes: [.generateBox(size: [1, 1, 1])])
			enemy.collision?.filter.group = enemies
			enemy.collision?.filter.mask = spells
			enemy.name = "ENEMY"
			
			let start = Point3D(
				x: enemyPaths[enemyPathsIndex].0,
				y: enemyPaths[enemyPathsIndex].1,
				z: enemyPaths[enemyPathsIndex].2
			)
			enemy.position = simd_float(start.vector + .init(x: 0, y: 0, z: -0.7))
			content.add(enemy)
			
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
//
			// Put skybox here.  See example in World project available at
			// https://developer.apple.com/
        }
		.gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
						print("Spatial tap gesture")
			let location3D = value.convert(value.location3D, from: .local, to: .scene)
			addCube(tapLocation: location3D)
		})
    }
	
	func addCube(tapLocation: SIMD3<Float>) {
//		let placementLocation = tapLocation + SIMD3<Float>(0, 0.2, 0)
		let placementLocation = SIMD3<Float>(0, 0.5, 0)
		let finalLocation = tapLocation + SIMD3<Float>(0, 0, -10)

		
		let iblComponent = ImageBasedLightComponent(source: .single(environmentResource!), intensityExponent: 0.25)

		let spell = ModelEntity(mesh: .generateBox(size: [1,1,1]), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
		spell.components.set(iblComponent)
		spell.components.set(ImageBasedLightReceiverComponent(imageBasedLight: spell))
		spell.name = "SPELL"

		spell.setPosition(placementLocation, relativeTo: nil)
		spell.collision = CollisionComponent(shapes: [.generateBox(size: [1, 1, 1])])
		spell.collision?.filter.group = spells
		spell.collision?.filter.mask = enemies

		contentView!.add(spell)
		
		let line = FromToByAnimation<Transform>(
			name: "line",
			from: .init(scale: .init(repeating: 1), translation: placementLocation),
			to: .init(scale: .init(repeating: 1), translation: finalLocation),
			duration: EnemySpawnParameters.speed / 4,
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
	(x: 1.757_231_498_429_01, y: 1.911_673_694_896_59, z: -8.094_368_331_589_704),
	(x: -0.179_269_237_592_594_17, y: 1.549_268_306_906_908_4, z: -7.254_713_426_424_875),
	(x: -0.013_296_800_013_828_491, y: 2.147_766_026_068_617_8, z: -8.601_541_438_900_849),
	(x: 2.228_704_746_539_703, y: 0.963_797_733_336_365_2, z: -7.183_621_312_117_454),
	(x: -0.163_925_123_812_864_4, y: 1.821_619_897_406_197, z: -8.010_893_563_433_282),
	(x: 0.261_716_575_589_896_03, y: 1.371_932_443_334_715, z: -7.680_206_361_333_17),
	(x: 1.385_410_631_256_254_6, y: 1.797_698_998_556_775_5, z: -7.383_548_882_448_866),
	(x: -0.462_798_470_454_367_4, y: 1.431_650_092_907_264_4, z: -7.169_154_476_151_876),
	(x: 1.112_766_805_791_563, y: 0.859_548_406_627_492_2, z: -7.147_229_496_720_969),
	(x: 1.210_194_536_657_374, y: 0.880_254_638_358_228_8, z: -8.051_132_737_691_349),
	(x: 0.063_637_772_899_141_52, y: 1.973_172_635_040_014_7, z: -8.503_837_407_474_947),
	(x: 0.883_082_630_134_997_2, y: 1.255_268_496_843_653_4, z: -7.760_994_300_660_705),
	(x: 0.891_719_821_716_725_7, y: 2.085_000_111_104_786_7, z: -8.908_048_018_555_112),
	(x: 0.422_260_067_132_894_2, y: 1.370_335_319_771_187, z: -7.525_853_388_894_509),
	(x: 0.473_470_811_107_753_46, y: 1.864_930_149_962_240_6, z: -8.164_641_191_459_626)
]


#Preview(immersionStyle: .full) {
    ImmersiveView()
}
