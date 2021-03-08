//
//  SourceViewController.swift
//  SwiftUISourceList
//
//  Created by cpahull on 08/03/2021.
//

import Cocoa

// Declare notifications to support prompts and data exchange between ContentView and ViewController
let selectedNodeAdded = NotificationCenter.default // Notification to add object at currently selected indexPath
    .publisher(for: Notification.Name("selectedNodeAdded"))
    .map {notification in
        return notification.userInfo
    }

let selectedNodeDeleted = NotificationCenter.default // Notification to delete object at currently selected indexPath
    .publisher(for: Notification.Name("selectedNodeDeleted"))

let selectedNodeMoved = NotificationCenter.default // Notification to move object at currently selected indexPath to indexPath passed
    .publisher(for: Notification.Name("selectedNodeMoved"))
    .map {notification in
        return notification.userInfo
    }

// Classes and variables to support userInfo in notifications (of nodes added, deleted and moved) received from ContentView
class NodeIndexPath {
    var indexPath = IndexPath()
    static let identifierKey = "indexPathKey"
}

class AddedNode {
    var node: Node? = nil
    static let identifierKey = "nodeKey"
}

var nodeIndexPath = NodeIndexPath()
var addedNode = AddedNode()

class SourceViewController: NSViewController, NSOutlineViewDataSource {
    
    @objc dynamic var contents = [Node]()
    var expandedNodes = [String]() // Supports use of persistent data to restore expanded nodes
    var itemsExpanded = false // Used to prevent spurious expansion/collapse after initial load

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var treeController: NSTreeController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set up observers to watch out for notifications received from ContentView
        NotificationCenter.default.addObserver(self, selector: #selector(addNodeAtIndexPath(_ :)), name: Notification.Name("selectedNodeAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteNodeAtIndexPath(_ :)), name: Notification.Name("selectedNodeDeleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveNodeToIndexPath(_ :)), name: Notification.Name("selectedNodeMoved"), object: nil)
        // Do view setup here.
    }
    
    @objc func addNodeAtIndexPath(_ notification: Notification) {
        let indexPath = treeController.selectionIndexPath
        let newNode = notification.userInfo![AddedNode.identifierKey] as! Node
        var targetPath: IndexPath = []
        if indexPath?.count == 1 {
            targetPath = IndexPath(indexes: [indexPath![0],0])
        } else {
            targetPath = IndexPath(indexes: [indexPath![0],indexPath![1],0])
        }
        treeController.setSelectionIndexPath(targetPath)
        treeController.addObject(newNode)
        contents = sortedNodes(nodes: contents)
    }

    @objc func deleteNodeAtIndexPath(_ notification: Notification) {
        let indexPath = treeController.selectionIndexPath
        treeController.removeObject(atArrangedObjectIndexPath: indexPath!)
    }
    
    @objc func moveNodeToIndexPath(_ notification: Notification) {
        let treeNode = treeController.selectedNodes[0] // get the NSTreeNode holding the object to be moved
        var destinationIndexPath = notification.userInfo?[NodeIndexPath.identifierKey] as! IndexPath
        destinationIndexPath.append(0) // select destination node's children array as target for appending the object moved's treeNode to
        treeController.move(treeNode, to: destinationIndexPath)
        contents = sortedNodes(nodes: contents)
    }

    @IBAction func nameCellEdited(_ sender: Any) {}
    
    func setContents(nodes: [Node]) {
        contents = nodes
        if itemsExpanded {return}
        expandedNodes = sortExpandedNodes(identifiers: expandedNodes)
        for i in 0 ..< expandedNodes.count {
            outlineView.expandItem(nodeFromIdentifier(anObject: expandedNodes[i]))
        }
    }
    
    func sortExpandedNodes(identifiers: [String]) -> [String] { // ensures parents will appear before their children
        var sortedExpandedNodes = [String]()
        var trees = [String]()
        for i in 0 ..< contents.count {
            trees.append(contents[i].name)
        }
        // put trees first
        for i in 0 ..< identifiers.count {
            if trees.contains(identifiers[i]) {
                sortedExpandedNodes.append(identifiers[i])
            }
        }
        // add branches after categories
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
        itemsExpanded = true
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

    
}
