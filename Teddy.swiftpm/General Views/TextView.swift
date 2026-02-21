//
//  TextView.swift
//  Teddy
//
//  Created by Morris Richman on 12/31/25.
//

import SwiftUI
import UIKit

struct TextView: View {
    @State private var height: CGFloat?
    @Binding private var text: String

    private let font: UIFont?
    private let textColor: UIColor?
    private let textAlignment: NSTextAlignment
    private let exclusionPaths: [UIBezierPath]

    private let isEditable: Bool
    private let isSelectable: Bool
    private let autocorrectionType: UITextAutocorrectionType
    private let autocapitalizationType: UITextAutocapitalizationType

    init(text: Binding<String>,
         font: UIFont? = .preferredFont(forTextStyle: .body),
         textColor: UIColor? = .label,
         textAlignment: NSTextAlignment = .left,
         exclusionPaths: [UIBezierPath],

         isEditable: Bool = false,
         isSelectable: Bool = false,
         autocorrectionType: UITextAutocorrectionType = .default,
         autocapitalizationType: UITextAutocapitalizationType = .sentences) {

      _text = text
      self.font = font
      self.textColor = textColor
      self.textAlignment = textAlignment
      self.exclusionPaths = exclusionPaths

      self.isEditable = isEditable
      self.isSelectable = isSelectable

      self.autocorrectionType = autocorrectionType
      self.autocapitalizationType = autocapitalizationType
    }

    init(text: String,
         font: UIFont? = .preferredFont(forTextStyle: .body),
         textColor: UIColor? = .label,
         textAlignment: NSTextAlignment = .left,
         exclusionPaths: [UIBezierPath],

         isEditable: Bool = false,
         isSelectable: Bool = false,
         autocorrectionType: UITextAutocorrectionType = .default,
         autocapitalizationType: UITextAutocapitalizationType = .sentences) {

        self = Self.init(text: .constant(text), font: font, textColor: textColor, textAlignment: textAlignment, exclusionPaths: exclusionPaths, isEditable: isEditable, isSelectable: isSelectable, autocorrectionType: autocorrectionType, autocapitalizationType: autocapitalizationType)
    }
    
    var body: some View {
        TextViewRepresentable(text: $text, height: $height, font: font, textColor: textColor, textAlignment: textAlignment, exclusionPaths: exclusionPaths, isEditable: isEditable, isSelectable: isSelectable, autocorrectionType: autocorrectionType, autocapitalizationType: autocapitalizationType)
            .frame(height: height)
    }
}

private struct TextViewRepresentable: UIViewRepresentable {
  typealias UIViewType = UITextView

  @Binding private var text: String
    @Binding private var height: CGFloat?

  private let font: UIFont?
  private let textColor: UIColor?
  private let textAlignment: NSTextAlignment
  private let exclusionPaths: [UIBezierPath]

  private let isEditable: Bool
  private let isSelectable: Bool
  private let autocorrectionType: UITextAutocorrectionType
  private let autocapitalizationType: UITextAutocapitalizationType

  init(text: Binding<String>,
       height: Binding<CGFloat?>,
       font: UIFont? = .systemFont(ofSize: 10),
       textColor: UIColor? = .black,
       textAlignment: NSTextAlignment = .left,
       exclusionPaths: [UIBezierPath],

       isEditable: Bool = false,
       isSelectable: Bool = false,
       autocorrectionType: UITextAutocorrectionType = .default,
       autocapitalizationType: UITextAutocapitalizationType = .sentences) {

    _text = text
      _height = height
    self.font = font
    self.textColor = textColor
    self.textAlignment = textAlignment
    self.exclusionPaths = exclusionPaths

    self.isEditable = isEditable
    self.isSelectable = isSelectable

    self.autocorrectionType = autocorrectionType
    self.autocapitalizationType = autocapitalizationType
  }

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
      
    return textView
  }

  func updateUIView(_ uiView: UITextView, context: Context) {
      
      uiView.backgroundColor = .clear

      uiView.text = text
      uiView.font = font
      uiView.textColor = textColor
      uiView.textAlignment = textAlignment
      uiView.isSelectable = isSelectable
      uiView.isEditable = isEditable
      uiView.textContainer.exclusionPaths = exclusionPaths

      uiView.autocorrectionType = autocorrectionType
      uiView.autocapitalizationType = autocapitalizationType
      
      DispatchQueue.main.async {
          height = uiView.sizeThatFits(uiView.visibleSize).height
      }
  }
}
