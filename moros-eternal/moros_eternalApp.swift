//
//  moros_eternalApp.swift
//  moros-eternal
//
//  Created by Gabriel Uribe on 4/20/24.
//

import SwiftUI

@main
struct moros_eternalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()

        }
		WindowGroup(id: "GameOverView") {
			GameOverView()
		}

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
