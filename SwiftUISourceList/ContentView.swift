//
//  ContentView.swift
//  SwiftUISourceList
//
//  Created by cpahull on 05/03/2021.
//

import SwiftUI

struct ContentView: View {
    
    @State private var nodes = [Node]()
    @State private var nodeID: UUID? = nil
    @State private var nodeName = ""
    
    var body: some View {
        HSplitView {
            SourceView(nodes: $nodes, nodeID: $nodeID, nodeName: $nodeName)
            DetailView(nodeID: $nodeID, nodeName: $nodeName)
        }
        .onAppear(perform: { // load nodes from file
            trees = Bundle.main.decode([Tree].self, from: "trees.json")
            // sort trees into type order; branches must come before leaves for populateNodes to work
            trees = trees.sorted { $0.type.rawValue < $1.type.rawValue}
            nodes = populateNodes()
            //nodeID = nodes[0].id // test code to show that pre-selection can be made, if required
            //nodeName = nodes[0].name
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

