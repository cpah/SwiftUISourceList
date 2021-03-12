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
    @State private var moveNodeSheetIsVisible = false
    @State private var newContent = true // prevents repeated call to setContents but supports forcing display updates
    
    var body: some View {
        HSplitView {
            VStack {
                HStack {
                    MenuButton("Add") {
                        Button("Branch"){
                            let index = getTreeIndex(forID: nodeID)
                            let newBranch = Tree(type: .branch, name: "New Branch", parentID: trees[index].id)
                            trees.append(newBranch)
                            // sort trees into type order; branches must come before leaves for populateNodes to work
                            trees = trees.sorted { $0.type.rawValue < $1.type.rawValue }
                            nodes = populateNodes()
                            newContent = true
                            nodeID = newBranch.id
                            nodeName = newBranch.name
                        }
                        .disabled(getNodeType(nodes: nodes, nodeID: nodeID) != .tree)
                        Button("Leaf") {
                            let index = getTreeIndex(forID: nodeID)
                            let newLeaf = Tree(type: .leaf, name: "New Leaf", parentID: trees[index].id)
                            trees.append(newLeaf)
                            nodes = populateNodes()
                            newContent = true
                            nodeID = newLeaf.id
                            nodeName = newLeaf.name
                        }
                    }
                    .disabled(nodeID == nil)
                    .disabled(getNodeType(nodes: nodes, nodeID: nodeID) == .leaf)
                    .frame(width: 60)
                    Button("Delete") {
                        let index = getTreeIndex(forID: nodeID)
                        trees.remove(at: index)
                        nodes = populateNodes()
                        newContent = true
                        nodeID = nil
                        nodeName = ""
                    }
                    .disabled(nodeID == nil)
                    .disabled(getNodeType(nodes: nodes, nodeID: nodeID) == .tree)
                    .disabled(nodeHasChildren(nodes: nodes, nodeID: nodeID))
                    Button("Move") {
                        newContent = true
                        moveNodeSheetIsVisible.toggle()
                    }
                    .disabled(nodeID == nil)
                    .disabled(getNodeType(nodes: nodes, nodeID: nodeID) != .leaf)
                }
                .padding(5)
                SourceVC(nodes: $nodes, nodeID: $nodeID, nodeName: $nodeName, newContent: $newContent)
            }
            DetailView(nodeID: $nodeID, nodeName: $nodeName)
            .frame(minWidth: 300, maxWidth: .infinity, maxHeight:.infinity)
        }
        .sheet(isPresented: $moveNodeSheetIsVisible, content: {
            MoveNodeSheet(moveNodeSheetIsVisible: $moveNodeSheetIsVisible, nodes: $nodes, nodeID: $nodeID)
        })
        .onAppear(perform: { // load nodes from file
            trees = Bundle.main.decode([Tree].self, from: "trees.json")
            trees = trees.sorted { $0.type.rawValue < $1.type.rawValue}
            nodes = populateNodes()
            //nodeID = nodes[0].id
            //nodeName = nodes[0].name
        })
    }
}

// Delegates are normally assigned in makeNSViewController() but we need an NSOutlineViewDelegate. Our outlineView is a property of SourceViewController and its NSOutlineViewDelegate does not exist until makeNSViewController(() has completed. We must assign our delegate in updateNSViewController(). We only need to assign our delegate once. This variable supports that. A global rather than a @State private var is used to avoid modifying it within its view, which is not supported
var sourceVCDelegateSet = false

struct SourceVC: NSViewControllerRepresentable {
    
    @Binding var nodes: [Node]
    @Binding var nodeID: UUID?
    @Binding var nodeName: String
    @Binding var newContent: Bool
        
    func makeNSViewController(context: Context) -> some NSViewController {
        let sourceVC = SourceViewController()
        return sourceVC
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        guard let sourceVC = nsViewController as? SourceViewController else {return}
        if newContent { // only update contents when they have changed
            sourceVC.setContents(nodes: nodes)
            let indexPath = getNodeIndexPath(nodes: nodes, nodeID: nodeID)
            if indexPath.count == 0 {
                sourceVC.treeController.removeSelectionIndexPaths(sourceVC.treeController.selectionIndexPaths)
            } else {
                sourceVC.treeController.setSelectionIndexPath(indexPath)
            }
        }
        if !sourceVCDelegateSet {
            sourceVC.outlineView?.delegate = context.coordinator
            sourceVCDelegateSet = true
        }
        if nodeID == nil {
            sourceVC.treeController.removeSelectionIndexPaths(sourceVC.treeController.selectionIndexPaths)
        }
    }
    
    class Coordinator: NSObject, NSOutlineViewDelegate {
        
        var parent: SourceVC
        
        init(_ parent: SourceVC) {
            self.parent = parent
        }
    
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            var view: NSTableCellView?
            var image: NSImage?
            guard let node = nodefromNSTreenode(from: item) else { return view }
            if node.type == .tree {
                view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = node.name.uppercased()
            return view
            } else {
                view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NameCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = node.name
                if node.type == .branch {
                    image = NSImage(named: NSImage.folderName)!
                } else {
                    image = NSImage(named: NSImage.menuMixedStateTemplateName)!
                }
                view?.imageView?.image = image
            }
            return view
        }
        
        func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
            guard let node = nodefromNSTreenode(from: item) else { return false }
            if node.type == .tree {return true}
            return false
        }
        
        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView = notification.object as? NSOutlineView else {return}
            guard self.parent.nodes.count > 0 else {return}
            self.parent.newContent = false // displayed contents have not changed
            guard outlineView.selectedRow >= 0 else {
                self.parent.nodeID = nil
                self.parent.nodeName = ""
                return
            }
            let node = nodefromNSTreenode(from: outlineView.item(atRow: outlineView.selectedRow)!)
            self.parent.nodeID = node?.id
            self.parent.nodeName = node?.name ?? ""
        }
        
        @IBAction func nameCellEdited(_ sender: Any) {
            guard let nameCell = sender as? NSTextField else {return}
            let treeIndex = getTreeIndex(forID: self.parent.nodeID)
            trees[treeIndex].name = nameCell.stringValue
            self.parent.nodeName = nameCell.stringValue
            // sort branch / leaf nodes alphabetically for new name
            let indexPath = getNodeIndexPath(nodes: self.parent.nodes, nodeID: self.parent.nodeID)
            if indexPath.count == 2 {
                self.parent.nodes[indexPath[0]].children = self.parent.nodes[indexPath[0]].children.sorted{ $0.name.lowercased() < $1.name.lowercased() }
            }
            if indexPath.count == 3 {
                self.parent.nodes[indexPath[0]].children[indexPath[1]].children = self.parent.nodes[indexPath[0]].children[indexPath[1]].children.sorted{ $0.name.lowercased() < $1.name.lowercased() }
            }
            self.parent.newContent = true
        }
        
        // Convert NSTreeNode to Node
        func nodefromNSTreenode (from item: Any) -> Node? {
            guard let treeNode = item as? NSTreeNode else {return nil}
                let node = treeNode.representedObject as? Node
                return node
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
}

struct DetailView: View {
    @Binding var nodeID: UUID?
    @Binding var nodeName: String

    var body: some View {
        VStack {
            Text(nodeID?.uuidString ?? "Nil")
            Text(nodeName)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

