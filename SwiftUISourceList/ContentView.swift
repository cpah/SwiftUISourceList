//
//  ContentView.swift
//  SwiftUISourceList
//
//  Created by cpahull on 05/03/2021.
//

import SwiftUI

enum NodeType: Int, Codable {
    case tree
    case branch
    case leaf
}

class Node: NSObject, Identifiable, Codable {
    var id = UUID()
    var type: NodeType
    @objc var name: String
    @objc var cleared: Bool
    @objc var children = [Node]()
    @objc var childrenCount: Int {return children.count}
    @objc var isLeaf: Bool {return children.count == 0}

    init(type: NodeType, name: String, cleared: Bool, children: [Node]) {
        self.type = type
        self.name = name
        self.cleared = cleared
        self.children = children
    }
}

struct ContentView: View {
    
    @State private var nodes = [Node]()
    
    var body: some View {
        Button("Load") {
            nodes = Bundle.main.decode([Node].self, from: "nodes.json")
            printNodes()
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension ContentView {
    
    func printNodes() {
        for i in 0 ..< nodes.count {
            print(nodes[i].name)
            for j in 0 ..< nodes[i].children.count {
                print(nodes[i].children[j].name)
                for k in 0 ..< nodes[i].children[j].children.count {
                    print(nodes[i].children[j].children[k].name)
                }
            }
        }
    }
}
