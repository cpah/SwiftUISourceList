//
//  MoveNodeSheet.swift
//  SwiftUISourceList
//
//  Created by cpahull on 08/03/2021.
//

import SwiftUI

struct MoveNodeSheet: View {
    
    @Binding var moveNodeSheetIsVisible: Bool
    @Binding var nodes: [Node]
    @Binding var nodeID: UUID?
    @State private var destinationNodes: [Node] = []
    @State private var selectedDestinationNodeID = UUID()
    
    var body: some View {
        VStack {
            HStack {
                Text("Move")
                Text(getNodeName(nodes: nodes, nodeID: nodeID))
            }
                .padding(.top, 10)
            Spacer()
            HStack {
                Text("From:")
                Text(getSourceIndexPathName())
            }
            HStack {
                Text("To:")
                Picker("", selection: $selectedDestinationNodeID) {
                    ForEach(destinationNodes) { node in
                        Text(node.name)
                    }
                }
            }
            .onAppear(perform: {
                destinationNodes = getdestinationNodes(nodes: nodes, nodeID: nodeID)
                if destinationNodes.count > 0 {
                    selectedDestinationNodeID = destinationNodes[0].id // pre-select first item in Picker list
                }
            })
            .padding(.leading, 10)
            .padding(.trailing,10)
            Spacer()
            HStack {
                Spacer()
                Button("Cancel"){
                    moveNodeSheetIsVisible = false
                }
                Button("OK") {
                    moveNodeSheetIsVisible = false
                    let index = getTreeIndex(forID: nodeID)
                    trees[index].parentID = selectedDestinationNodeID
                    nodes = populateNodes()
                }
            }
            .padding(.bottom, 10)
            .padding(.trailing, 5)
        }
        .frame(width: 300, height: 110)
    }
    
    func getSourceIndexPathName() -> String {
        var nodeIndexPath = getNodeIndexPath(nodes: nodes, nodeID: nodeID)
        nodeIndexPath.removeLast()
        if nodeIndexPath.count == 1 {
            return nodes[nodeIndexPath[0]].name
        } else {
            return nodes[nodeIndexPath[0]].children[nodeIndexPath[1]].name
        }
    }
    
}

