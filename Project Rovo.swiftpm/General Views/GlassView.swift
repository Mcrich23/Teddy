//
//  GlassView.swift
//  Project Rovo
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

public struct GlassView: View {
    /// Defaults to 3
    var variant: Int

    public init(variant: Int = 3) {
        self.variant = variant
    }

    public var body: some View {
        Representable(glassVariant: variant)
    }
}

// MARK: - Representable

private struct Representable: UIViewRepresentable {
    var glassVariant: Int
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        context.coordinator.blurView
    }
    
    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        guard let glass = _UIViewGlass(variant: glassVariant) else { return }
        context.coordinator.update(glass: glass)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

// MARK: - Coordinator

extension Representable {
    @MainActor
    class Coordinator {
        let blurView = {
            let effectClass: AnyClass? = NSClassFromString("UIGlassContainerEffect")
            let effect: UIVisualEffect? = {
                guard let effectClass = effectClass else { return nil }
                return (effectClass as! NSObject.Type).init() as? UIVisualEffect
            }()
            
            return UIVisualEffectView(effect: effect)
        }()
        
        func update(glass: NSObject) {
            blurView.effect = createGlassEffect(glass: glass)
        }
        
        private func createGlassEffect(glass: NSObject) -> UIVisualEffect? {
            // UIGlassEffect:
            // Class Methods:
            //  + (id) effectWithGlass:(id)arg1
            //  + (id) effectWithStyle:(long)arg1
            // Instance Methods:
            //  - (void) setStyle:(long)arg1
            //  - (long) style
            //  - (void) setInteractive:(BOOL)arg1
            //  - (id) glass
            //  - (BOOL) isInteractive
            //  - (void) setTintColor:(id)arg1
            //  - (id) tintColor
            guard let glassEffectClass = NSClassFromString("UIGlassEffect") else {
                return nil
            }
            
            let selector = NSSelectorFromString("effectWithGlass:")
            
            guard glassEffectClass.responds(to: selector) else {
                return nil
            }
            
            let method = glassEffectClass.method(for: selector)
            typealias EffectWithGlassFunc = @convention(c) (AnyClass, Selector, NSObject) -> UIVisualEffect?
            let effectWithGlass = unsafeBitCast(method, to: EffectWithGlassFunc.self)
            
            return effectWithGlass(glassEffectClass, selector, glass)
        }
    }
}
