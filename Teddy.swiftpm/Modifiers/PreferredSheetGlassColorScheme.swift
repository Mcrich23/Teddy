//
//  PreferredSheetGlassColorScheme.swift
//  Teddy
//
//  Created by Morris Richman on 2/24/26.
//

import SwiftUI

struct PreferredSheetGlassColorSchemeKey: PreferenceKey {
    static let defaultValue: ColorScheme = .light

    static func reduce(value: inout ColorScheme, nextValue: () -> ColorScheme) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func preferredSheetGlassColorScheme(_ colorScheme: ColorScheme) -> some View {
        preference(key: PreferredSheetGlassColorSchemeKey.self, value: colorScheme)
    }
}

extension EnvironmentValues {
    @Entry var preferredSheetGlassColorScheme = PreferredSheetGlassColorSchemeKey.defaultValue
}
