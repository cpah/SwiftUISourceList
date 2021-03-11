//
//  Nodes.swift
//  SwiftUISourceList
//
//  Created by cpahull on 08/03/2021.
//

import Foundation

let ROOTID = UUID()

enum NodeType: Int, Codable {
    case tree
    case branch
    case leaf
    case undefined
}

struct Tree: Identifiable, Codable {
    
    var id = UUID()
    var type: NodeType
    var name: String
    var parentID: UUID
    
    init(type: NodeType, name: String, parentID: UUID) {
        
        self.type = type
        self.name = name
        self.parentID = parentID
    }
}

var trees = [Tree]()

func getTreeIndex(forID: UUID?) -> Int {
    guard forID != nil else {return -1}
    for i in 0 ..< trees.count {
        if trees[i].id == forID {
            return i
        }
    }
    return -1
}

class Node: NSObject, Identifiable, Codable {
    var id: UUID
    var type: NodeType
    @objc var name: String
    @objc var children = [Node]()
    @objc var childrenCount: Int {return children.count}
    @objc var isLeaf: Bool {return children.count == 0}

    init(id: UUID, type: NodeType, name: String, children: [Node]) {
        self.id = id
        self.type = type
        self.name = name
        self.children = children
    }
}

func populateNodes() -> [Node] {

    var nodes = [Node]()
    
    // get treeNodes first
    for i in 0 ..< trees.count {
        if trees[i].type == .tree {
            nodes.append(Node(id: trees[i].id, type: trees[i].type, name: trees[i].name, children: []))
        }
    }

    for i in 0 ..< trees.count {
        if trees[i].type != .tree {
            for j in 0 ..< nodes.count {
                if nodes[j].id == trees[i].parentID {
                    nodes[j].children.append(Node(id: trees[i].id, type: trees[i].type, name: trees[i].name, children: []))
                }
                for k in 0 ..< nodes[j].children.count {
                    if nodes[j].children[k].id == trees[i].parentID {
                        nodes[j].children[k].children.append(Node(id: trees[i].id, type: trees[i].type, name: trees[i].name, children: []))
                    }
                }
            }
        }
    }
    // sort nodes at Branch and Leaf level
    for i in 0 ..< nodes.count {
        nodes[i].children = nodes[i].children.sorted(by: { $0.name.lowercased() < $1.name.lowercased()})
        for j in 0 ..< nodes[i].children.count {
            nodes[i].children[j].children = nodes[i].children[j].children.sorted(by: { $0.name.lowercased() < $1.name.lowercased()})
        }
    }

    return nodes
}

// get a node's indexPath (based on its identifier)
func getNodeIndexPath(nodes: [Node], nodeID: UUID?) -> IndexPath {
    for i in 0 ..< nodes.count {
        if nodes[i].id == nodeID {
            return [i]
        }
        for j in 0 ..< nodes[i].children.count {
            if nodes[i].children[j].id == nodeID {
                return [i, j]
            }
            for k in 0 ..< nodes[i].children[j].children.count {
                if nodes[i].children[j].children[k].id == nodeID {
                    return [i, j, k]
                }
            }
        }
    }
    return []
}

// get a node's type (based on its identifier)
func getNodeType(nodes: [Node], nodeID: UUID?) -> NodeType {
    for i in 0 ..< nodes.count {
        if nodes[i].id == nodeID {
            return nodes[i].type
        }
        for j in 0 ..< nodes[i].children.count {
            if nodes[i].children[j].id == nodeID {
                return nodes[i].children[j].type
            }
            for k in 0 ..< nodes[i].children[j].children.count {
                if nodes[i].children[j].children[k].id == nodeID {
                    return nodes[i].children[j].children[k].type
                }
            }
        }
    }
    return .undefined
}

// get a node's name (based on its identifier)
func getNodeName(nodes: [Node], nodeID: UUID?) -> String {
    for i in 0 ..< nodes.count {
        if nodes[i].id == nodeID {
            return nodes[i].name
        }
        for j in 0 ..< nodes[i].children.count {
            if nodes[i].children[j].id == nodeID {
                return nodes[i].children[j].name
            }
            for k in 0 ..< nodes[i].children[j].children.count {
                if nodes[i].children[j].children[k].id == nodeID {
                    return nodes[i].children[j].children[k].name
                }
            }
        }
    }
    return ""
}

// check if node has children (to prevent deletion of parent node)
func nodeHasChildren(nodes: [Node], nodeID: UUID?) -> Bool {
    let indexPath = getNodeIndexPath(nodes: nodes, nodeID: nodeID)
    switch indexPath.count {
    case 1:
        return nodes[indexPath[0]].children.count > 0
    case 2:
        return nodes[indexPath[0]].children[indexPath[1]].children.count > 0
    default:
        return false
    }
}

// get the possible destination nodes if selected node were to be moved
func getdestinationNodes(nodes: [Node], nodeID: UUID?) -> [Node] {
    var destinationNodes: [Node] = []
    guard nodeID != nil else {return destinationNodes}
    let sourceIndexPath = getNodeIndexPath(nodes: nodes, nodeID: nodeID)
    if sourceIndexPath.count <= 1 {return destinationNodes} // it's a tree or selection not passed on launch
    if sourceIndexPath.count == 3 { // it's within a branch so its tree is a valid destination node
        destinationNodes.append(nodes[sourceIndexPath[0]])
    }
    for i in 0 ..< nodes[sourceIndexPath[0]].children.count {
        // exclude self (for branches) and any leaves
        if nodes[sourceIndexPath[0]].children[i].id != nodes[sourceIndexPath[0]].children[sourceIndexPath[1]].id && nodes[sourceIndexPath[0]].children[i].type != .leaf {
            destinationNodes.append(nodes[sourceIndexPath[0]].children[i])
        }
    }
    return destinationNodes
}

