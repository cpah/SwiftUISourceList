//
//  SourceViewController.swift
//  SwiftUISourceList
//
//  Created by cpahull on 08/03/2021.
//

import Cocoa

class SourceViewController: NSViewController, NSOutlineViewDataSource {
    
    @objc dynamic var contents = [Node]()
    var expandedNodes = [String]() // Supports use of persistent data to restore expanded nodes
    var savedExpandedNodes = [String]() // Supports persistence of expansions when contents reloaded

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var treeController: NSTreeController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        view.window?.makeFirstResponder(outlineView)
    }
    
    @IBAction func nameCellEdited(_ sender: Any) {} // Stub for delegate to surpress spurious warning
    
    func setContents(nodes: [Node]) {
        savedExpandedNodes = getExpandedNodeIDs()
        contents = nodes
        if savedExpandedNodes.count > 0 { // restore expanded nodes when refreshing view
            for i in 0 ..< savedExpandedNodes.count {
                outlineView.expandItem(nodeFromIdentifier(anObject: savedExpandedNodes[i]))
            }
        } else { // restore expanded nodes saved on termination
            // Sort expanded nodes so that parents will be expanded before (any of) their children
            if expandedNodes.count > 0 {
                expandedNodes = sortExpandedNodes(identifiers: expandedNodes)
                for i in 0 ..< expandedNodes.count {
                    outlineView.expandItem(nodeFromIdentifier(anObject: expandedNodes[i]))
                }
            }
        }
    }
    
    func sortExpandedNodes(identifiers: [String]) -> [String] { // ensures parents will appear before their children
        var sortedExpandedNodes = [String]()
        var trees = [String]()
        for i in 0 ..< contents.count {
            trees.append(contents[i].id.uuidString)
        }
        // put trees first
        for i in 0 ..< identifiers.count {
            if trees.contains(identifiers[i]) {
                sortedExpandedNodes.append(identifiers[i])
            }
        }
        // add branches after trees
        for i in 0 ..< identifiers.count {
            if !trees.contains(identifiers[i]) {
                sortedExpandedNodes.append(identifiers[i])
            }
        }
        return sortedExpandedNodes
    }
    
    // encode expanded node identifiers for saving as persistent data
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        guard let node = nodefromNSTreenode(from: item!) else {return false}
        return node.id.uuidString
    }
    
    // retrieve expanded node identifiers from persistent data and append them to a local array (for processing once treeController has been instantiated
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        expandedNodes.append(object as! String)
        return nil
    }

    // Convert NSTreeNode to Node
    func nodefromNSTreenode (from item: Any) -> Node? {
        guard let treeNode = item as? NSTreeNode else {return nil}
            let node = treeNode.representedObject as? Node
            return node
    }
    // find the treeNode associated with an identifier (by name) by processing identifier (name here because identifier changes on each app launch) - and treeController nodes array in next function
    private func nodeFromIdentifier(anObject: Any) -> NSTreeNode? {
        return nodeFromIdentifier(anObject: anObject, nodes: treeController.arrangedObjects.children)
    }

    // search all levels of tree structure (recursively) to find treeNode associated with the passed identifier (name)
    private func nodeFromIdentifier(anObject: Any, nodes: [NSTreeNode]!) -> NSTreeNode? {
        var treeNode: NSTreeNode?
        for node in nodes {
            if let testNode = node.representedObject as? Node {
                let idCheck = anObject as? String
                if idCheck == testNode.id.uuidString {
                    treeNode = node
                    break
                }
                if node.children != nil {
                    if let nodeCheck = nodeFromIdentifier(anObject: anObject, nodes: node.children) {
                        treeNode = nodeCheck
                        break
                    }
                }
            }
        }
        return treeNode
    }
    
    func getExpandedNodeIDs() -> [String] { // supports saving expanded nodes when refreshing views (non-persistent data)
        var expandedNodeIDs = [String]()
        var node:Node? = nil
        for i in 0 ..< treeController.arrangedObjects.children!.count {
            node = nodefromNSTreenode(from: treeController.arrangedObjects.children?[i] as Any)
            if outlineView.isItemExpanded(treeController.arrangedObjects.children?[i]) {
                expandedNodeIDs.append(node!.id.uuidString)
            }
            if treeController.arrangedObjects.children![i].children != nil {
                for j in 0 ..< treeController.arrangedObjects.children![i].children!.count {
                    node = nodefromNSTreenode(from: treeController.arrangedObjects.children?[i].children?[j] as Any)
                    if outlineView.isItemExpanded(treeController.arrangedObjects.children?[i].children?[j]) {
                        expandedNodeIDs.append(node!.id.uuidString)
                    }
                }
            }
        }
        return expandedNodeIDs
    }

}

