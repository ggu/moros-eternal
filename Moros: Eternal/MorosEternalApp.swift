//
//  Moros__EternalApp.swift
//  Moros: Eternal
//
//  Created by Gabriel Uribe on 4/20/24.
//

import SwiftUI

@main
struct MorosEternalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
