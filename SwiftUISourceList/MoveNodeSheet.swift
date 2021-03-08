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
    @State private var destinationIndexPath: IndexPath = []
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
                    destinationIndexPath = []
                    moveNodeSheetIsVisible = false
                }
                Button("OK"){
                    destinationIndexPath = getNodeIndexPath(nodes: nodes, nodeID: selectedDestinationNodeID)
                    moveNodeSheetIsVisible = false
                    if destinationIndexPath.count > 0 {
                        nodeIndexPath.indexPath = destinationIndexPath
                        // post notification to OutlineViewController to move selected node to indexPath passed
                        NotificationCenter.default.post(name: Notification.Name("selectedNodeMoved"), object: self, userInfo: [NodeIndexPath.identifierKey:nodeIndexPath.indexPath])
                    }
                }
            }
            .padding(.bottom,10)
        }
        .frame(width: 300, height: 150)
    }
    
    func getSourceIndexPathName() -> String {
        var sourceIndexPath = getNodeIndexPath(nodes: nodes, nodeID: nodeID)
        sourceIndexPath.removeLast()
        if sourceIndexPath.count == 1 {
            return nodes[sourceIndexPath[0]].name
        }
        return nodes[sourceIndexPath[0]].children[sourceIndexPath[1]].name
    }
    
}

struct MoveNodeSheet_Previews: PreviewProvider {
    @State static var moveNodeSheetIsVisible = true
    @State static var nodes = [Node(type: .leaf, name: "Leaf 1", children: [])]
    @State static var nodeID: UUID? = nil
    static var previews: some View {
        MoveNodeSheet(moveNodeSheetIsVisible: $moveNodeSheetIsVisible, nodes: $nodes, nodeID: $nodeID)
    }
}
