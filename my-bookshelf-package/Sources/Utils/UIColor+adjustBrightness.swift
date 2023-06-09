import UIKit
import SwiftUI

// https://stackoverflow.com/questions/38435308/get-lighter-and-darker-color-variations-for-a-given-uicolor
public extension UIColor {
    /// creates a lighter color
    func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: abs(percentage))
    }

    /// creates a darker color
    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: -abs(percentage))
    }

    /// increase brightness or decrease saturation
    func adjustBrightness(by percentage: CGFloat = 30.0) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b < 1.0 {
                let newB: CGFloat = max(min(b + (percentage/100.0)*b, 1.0), 0.0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - (percentage/100.0)*s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        return self
    }
}

public extension Color {
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return Color(UIColor(self).adjustBrightness(by: abs(percentage)))
    }

    /// creates a darker color
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return Color(UIColor(self).adjustBrightness(by: -abs(percentage)))
    }
}
