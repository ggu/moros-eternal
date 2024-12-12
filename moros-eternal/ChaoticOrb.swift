import SwiftUI
import RealityKit
import RealityKitContent
import AVFAudio

/// A magical orb that appears after defeating a certain number of dragons.
/// The orb moves in a semicircular pattern and can be destroyed by spells.
class ChaoticOrb {
    let entity: ModelEntity
    private var dragonKillCount: Int = 0
    
    init() {
        self.entity = ModelEntity()
        self.entity.name = "CHAOTIC_ORB"
        
        // Load and setup the orb model
        if let model = try? ModelEntity.load(named: "BlueOrbRCP.usdz") {
            self.entity.addChild(model)
        }
        
        // Configure collision detection
        self.entity.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.5)])
        self.entity.generateCollisionShapes(recursive: true)
    }
    
    /// Creates a semicircular movement pattern for the orb
    func moveChaotically() {
        // Configure movement parameters
        let duration: TimeInterval = 5.0
        let radius: Float = 5.0
        let centerZ: Float = -5.0
        let numPoints = 10
        
        // Create waypoints for the semicircular path
        var waypoints: [Transform] = []
        for i in 0...numPoints {
            let progress = Float(i) / Float(numPoints)
            let angle = progress * .pi
            
            let x = radius * cos(angle)
            let z = centerZ - radius * sin(angle)
            
            let transform = Transform(
                scale: .one,
                rotation: simd_quatf(angle: progress * 2 * .pi, axis: [0, 1, 0]),
                translation: simd_float3(x, 1, z)
            )
            waypoints.append(transform)
        }
        
        // Initialize position and orientation
        entity.setPosition(waypoints[0].translation, relativeTo: nil)
        entity.orientation = waypoints[0].rotation
        
        // Animate through waypoints
        for (index, waypoint) in waypoints.enumerated() {
            let delay = duration * Double(index) / Double(waypoints.count)
            let segmentDuration = duration / Double(waypoints.count)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                _ = self.entity.move(
                    to: waypoint,
                    relativeTo: nil,
                    duration: segmentDuration,
                    timingFunction: .easeInOut
                )
            }
        }
        
        // Remove orb after movement completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.entity.removeFromParent()
        }
    }
    
    /// Handles dragon kill events and spawns the orb when conditions are met
    /// - Parameters:
    ///   - dragonKillCount: Current number of dragons killed
    ///   - contentView: The RealityKit content view to add the orb to
    static func handleDragonKill(dragonKillCount: Int, contentView: RealityViewContent) {
        print("Dragon killed! Count: \(dragonKillCount)")
        
        if dragonKillCount == 10 {
            print("Spawning Chaotic Orb!")
            let orb = ChaoticOrb()
            contentView.add(orb.entity)
            orb.moveChaotically()
            
            // Reset the dragon kill count
            moros_eternal.dragonKillCount = 0
        }
    }
}
