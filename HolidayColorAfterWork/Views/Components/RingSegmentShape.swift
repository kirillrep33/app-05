import SwiftUI

struct RingSegmentShape: Shape {
    let start: CGFloat
    let end: CGFloat
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * (1 - thickness)
        let startAngle = Angle(degrees: (Double(start) * 360) - 90)
        let endAngle = Angle(degrees: (Double(end) * 360) - 90)

        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}
