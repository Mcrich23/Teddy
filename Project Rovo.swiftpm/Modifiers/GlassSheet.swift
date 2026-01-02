//
//  GlassSheet.swift
//  Project Rovo
//
//  Created by Morris Richman on 12/31/25.
//

import Foundation
import SwiftUI

extension View {
    public func glassSheet(variant: Int = 4) -> some View {
        background{ VCWrapper(variant: variant) }
    }
}

fileprivate struct VCWrapper: UIViewControllerRepresentable {
    let variant: Int
    
    @MainActor final class DummyVC: UIViewController {
        let variant: Int
        
        init(variant: Int) {
            self.variant = variant
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
        }
        
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            
            guard let sheetPresentationController = parent?.sheetPresentationController else {
                return
            }
            
            let glassView = _UIViewGlass(variant: variant)
            
            sheetPresentationController.perform(NSSelectorFromString("_setLargeBackground:"), with: glassView)
            sheetPresentationController.perform(NSSelectorFromString("_setNonLargeBackground:"), with: glassView)
        }
    }

    func makeUIViewController(context: Context) -> DummyVC {
        .init(variant: variant)
    }
    func updateUIViewController(_ uiViewController: DummyVC, context: Context) {
    }
}

public func _UIViewGlass(variant: Int) -> NSObject? {
    let glassClass = objc_lookUpClass("_UIViewGlass")! as AnyObject
    let glass = glassClass._alloc()._init(variant: variant)
    return glass as? NSObject
}

/// Registers Objective-C methods Swift needs.
fileprivate final class PrivateSelectors: NSObject {

    @objc(alloc)
    func _alloc() -> AnyObject {
        fatalError("Do not call")
    }

    @objc(initWithVariant:)
    func _init(variant: Int) -> AnyObject {
        fatalError("Do not call")
    }
}
