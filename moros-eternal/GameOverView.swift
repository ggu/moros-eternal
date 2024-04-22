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
			Spacer()
			Model3D(named: "Demon_Dragon_Full_Texture.usdz")
				.padding(.bottom, 50)
				.scaleEffect(0.5)

			Text("Game Over")
				.font(.title)
			
			Text("Score: \(score)")
			
			Button("Replay") {
				Task {
					await dismissImmersiveSpace()
					isGameOver = false
					enemyEntities.removeAll()
					timeElapsed = 0
					score = 0
					await openImmersiveSpace(id: "ImmersiveSpace")
					dismissWindow(id: "GameOverView")
				}
			}
			.font(.title)
			.padding(24)
		}
			.padding()
		}
	}

//#Preview(windowStyle: .automatic) {
//	GameOverView()
//}
