//
//  GlassView.swift
//  Teddy
//
//  Created by Morris Richman on 1/15/26.
//

import SwiftUI

public struct GlassView: View {
    /// Defaults to 3
    var variant: Int?
    
    /// Transition animation
    var animation: Animation?

    public init(variant: Int? = 3, animation: Animation? = nil) {
        self.variant = variant
        self.animation = animation
    }

    public var body: some View {
        Representable(glassVariant: variant, animation: animation)
    }
}

// MARK: - Representable

private struct Representable: UIViewRepresentable {
    var glassVariant: Int?
    var animation: Animation?
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        context.coordinator.blurView
    }
    
    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        if let glassVariant {
            context.coordinator.update(glass: _UIViewGlass(variant: glassVariant), animation: animation)
        } else {
            context.coordinator.update(glass: nil, animation: animation)
        }
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
        
        func update(glass: NSObject?, animation: Animation?) {
            guard let glass else {
                animate(animation) {
                    self.blurView.effect = nil
                }
                return
            }
            
            animate(animation) {
                self.blurView.effect = self.createGlassEffect(glass: glass)
            }
        }
        
        private func animate(_ animation: Animation?, action: @escaping () -> Void) {
            if let animation {
                UIView.animate(animation) {
                    action()
                }
            } else {
                action()
            }
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
