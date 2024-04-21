//
//  ContentView.swift
//  moros-eternal
//
//  Created by Gabriel Uribe on 4/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
	@Environment(\.dismissWindow) var dismissWindow

    var body: some View {
        VStack {
			Spacer()
            Model3D(named: "Demon_Dragon_Full_Texture.usdz")
                .padding(.bottom, 50)
				.scaleEffect(0.5)

            Text("Moros: Academy")
				.font(.title)
			
			Button("Start Game", action: {
				Task {
					switch await openImmersiveSpace(id: "ImmersiveSpace") {
					case .opened:
						immersiveSpaceIsShown = true
						dismissWindow(id: "ContentView")
					case .error, .userCancelled:
						fallthrough
					@unknown default:
						immersiveSpaceIsShown = false
						showImmersiveSpace = false
					}
				}
			})
			.font(.title)
			.padding(24)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
