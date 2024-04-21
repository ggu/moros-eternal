//
//  ContentView.swift
//  moros-eternal
//
//  Created by Gabriel Uribe on 4/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct GameOverView: View {
	
	@Environment(\.openImmersiveSpace) var openImmersiveSpace
	@Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
	@Environment(\.dismissWindow) var dismissWindow
	
	var body: some View {
		VStack {
			Model3D(named: "Scene", bundle: realityKitContentBundle)
				.padding(.bottom, 50)
			
			Text("Game Over")
				.frame(width: 360)
				.padding(24)
				.glassBackgroundEffect()
			
			Text("Score: \(score)")
			
			Button("Replay") {
				Task {
					await dismissImmersiveSpace()
					isGameOver = false
					score = 0
					await openImmersiveSpace(id: "ImmersiveSpace")
					dismissWindow(id: "GameOverView")
				}
			}
		}
			.padding()
		}
	}

//#Preview(windowStyle: .automatic) {
//	GameOverView()
//}
