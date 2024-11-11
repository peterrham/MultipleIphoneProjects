//
//  Untitled.swift
//  V2NoScopesApp
//
//  Created by Ham, Peter on 11/10/24.
//

/* XXX, this currently does not work
 
import SwiftUI

protocol DynamicView: View {
    static var viewTitle: String { get }
    
    func testInit ()
}

// This could be placed in a helper file, e.g., `ViewDiscovery.swift`
var dynamicViewTypes: [any DynamicView.Type] = []

// Register each conforming type here
func registerDynamicViews() {
    dynamicViewTypes = [
        FirstDynamicView.self,
        SecondDynamicView.self
        // Add more conforming types as needed
    ]
}

func discoverDynamicViews() -> [AnyView] {
    // Ensure types are registered
    registerDynamicViews()
    
    // Map each registered type to an instance wrapped in `AnyView`
    return dynamicViewTypes.map { viewType in
        viewType.testInit()
    }
}


struct FirstDynamicView: DynamicView {
    static var viewTitle: String { "First Dynamic View" }
    
    var body: some View {
        Text("This is the First Dynamic View")
    }
}

struct SecondDynamicView: DynamicView {
    static var viewTitle: String { "Second Dynamic View" }
    
    var body: some View {
        Text("This is the Second Dynamic View")
    }
}

func discoverDynamicViews() -> [AnyView] {
    var dynamicViews: [AnyView] = []
    
    let mirror = Mirror(reflecting: self)
    
    for case let child in mirror.children {
        if let dynamicType = child.value as? DynamicView.Type {
            let view = dynamicType.init()
            dynamicViews.append(AnyView(view))
        }
    }
    return dynamicViews
}
*/

