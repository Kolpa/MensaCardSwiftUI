//
//  ContentView.swift
//  MensaCardSwiftUI
//
//  Created by Opahle, Kolya on 24.09.19.
//  Copyright © 2019 Opahle, Kolya. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var mensaCardData = MensaCardData()
    
    var body: some View {
        VStack {
            Text("Card Credits: \(String(format: "%.2f", self.mensaCardData.credits))")
            .onAppear {
                self.mensaCardData.scanCard()
            }
            Button(action: {
                self.mensaCardData.scanCard()
            }) {
                Text("Scan Again")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
