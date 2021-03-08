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
    
    var body: some View {
        VStack {
            HStack {
                Button("Add Branch"){
                    // post notification (with new Branch node) to ViewController to add node to selected node
                    addedNode.node = Node(type: .branch, name: "New Branch", children: [])
                    NotificationCenter.default.post(name: Notification.Name("selectedNodeAdded"), object: self, userInfo: [AddedNode.identifierKey:addedNode.node!])
                }
                .disabled(getNodeType(nodes: nodes, nodeID: nodeID) != .tree)
                Button("Add Leaf") {
                    // post notification (with new Leaf node) to ViewController to add node to selected node
                    addedNode.node = Node(type: .leaf, name: "New Leaf", children: [])
                    NotificationCenter.default.post(name: Notification.Name("selectedNodeAdded"), object: self, userInfo: [AddedNode.identifierKey:addedNode.node!])
                }
                .disabled(nodeID == nil)
                .disabled(getNodeType(nodes: nodes, nodeID: nodeID) == .leaf)
            }
            .padding(.top, 5)
            HStack {
                Button("Delete") {
                    // post notification to OutlineViewController to delete selected node
                    NotificationCenter.default.post(name: Notification.Name("selectedNodeDeleted"), object: self)
                    nodeID = nil
                    nodeName = ""
                }
                .disabled(nodeID == nil)
                .disabled(getNodeType(nodes: nodes, nodeID: nodeID) == .tree)
                .disabled(nodeHasChildren(nodes: nodes, nodeID: nodeID))
                Button("Move") {
                    moveNodeSheetIsVisible.toggle()
                }
                .disabled(nodeID == nil)
                .disabled(getNodeType(nodes: nodes, nodeID: nodeID) != .leaf)
            }
            SourceVC(nodes: $nodes, nodeID: $nodeID, nodeName: $nodeName)
            VStack {
                Text(nodeID?.uuidString ?? "Nil")
                Text(nodeName)
            }
            .padding(.bottom, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $moveNodeSheetIsVisible, content: {
            MoveNodeSheet(moveNodeSheetIsVisible: $moveNodeSheetIsVisible, nodes: $nodes, nodeID: $nodeID)
        })
        .onAppear(perform: { // load nodes from file
            nodes = Bundle.main.decode([Node].self, from: "nodes.json")
            nodeID = nodes[0].id
            nodeName = nodes[0].name
        })
    }
}

var sourceVCDelegateSet = false

struct SourceVC: NSViewControllerRepresentable {
    
    @Binding var nodes: [Node]
    @Binding var nodeID: UUID?
    @Binding var nodeName: String
        
    func makeNSViewController(context: Context) -> some NSViewController {
        let sourceVC = SourceViewController()
        return sourceVC
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        guard let sourceVC = nsViewController as? SourceViewController else {return}
        sourceVC.setContents(nodes: nodes)
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
                    image = NSImage(named: NSImage.multipleDocumentsName)!
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
            self.parent.nodeName = nameCell.stringValue
            let indexPath = getNodeIndexPath(nodes: self.parent.nodes, nodeID: self.parent.nodeID)
            if indexPath.count == 2 {
                self.parent.nodes[indexPath[0]].children = self.parent.nodes[indexPath[0]].children.sorted{ $0.name.lowercased() < $1.name.lowercased() }
            }
            if indexPath.count == 3 {
                self.parent.nodes[indexPath[0]].children[indexPath[1]].children = self.parent.nodes[indexPath[0]].children[indexPath[1]].children.sorted{ $0.name.lowercased() < $1.name.lowercased() }
            }
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
    
    func countNodes() -> Int {
        var count = 0
        count += nodes.count
        for i in 0 ..< nodes.count {
            count += nodes[i].children.count
            for j in 0 ..< nodes[i].children.count {
                count += nodes[i].children[j].children.count
            }
        }
        return count
    }
}
