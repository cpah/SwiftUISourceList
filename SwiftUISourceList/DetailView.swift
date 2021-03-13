//
//  DetailView.swift
//  SwiftUISourceList
//
//  Created by cpahull on 12/03/2021.
//

import SwiftUI

struct DetailView: View {
    @Binding var nodeID: UUID?
    @Binding var nodeName: String

    var body: some View {
        VStack {
            Text(nodeID?.uuidString ?? "Nil")
            Text(nodeName)
        }
        .frame(minWidth: 300, maxWidth: .infinity, maxHeight:.infinity)
    }
}

struct DetailView_Previews: PreviewProvider {
    @State static var nodeID: UUID? = UUID()
    @State static var nodeName = "nodeName"
    static var previews: some View {
        DetailView(nodeID: $nodeID, nodeName: $nodeName)
    }
}
