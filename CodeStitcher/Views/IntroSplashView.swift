import SwiftUI

/// 100% Native SwiftUI GPU Canvas Cinematic Studio Intro.
/// Locked 120 FPS, pre-allocated geometry, tap-to-skip, zero cold-start delay.
struct IntroSplashView: View {
    var onFinished: () -> Void
    
    @State private var animProgress: CGFloat = 0.0
    @State private var animationStarted: Bool = false
    @State private var isFinished: Bool = false
    
    private func finishSplash() {
        guard !isFinished else { return }
        isFinished = true
        onFinished()
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if animationStarted {
                Canvas { context, size in
                    let t = animProgress
                    func phase(_ start: CGFloat, _ end: CGFloat) -> CGFloat {
                        if t < start { return 0.0 }
                        if t > end { return 1.0 }
                        return (t - start) / (end - start)
                    }
                    
                    let cap1Draw = phase(0.00, 0.35)
                    let cap1Fill = phase(0.35, 0.55)
                    let cap2Draw = phase(0.06, 0.41)
                    let cap2Fill = phase(0.41, 0.60)
                    let stitchDraw = phase(0.20, 0.40)
                    let textDraw = phase(0.12, 0.45)
                    let textFill = phase(0.45, 0.65)
                    
                    let globalAlpha: CGFloat = t < 0.88 ? 1.0 : (1.0 - phase(0.88, 1.00))
                    
                    let targetW: CGFloat = 1000.0
                    let targetH: CGFloat = 360.0
                    let scale = min((size.width * 0.90) / targetW, (size.height * 0.70) / targetH)
                    let offsetX = (size.width - targetW * scale) / 2.0
                    let offsetY = (size.height - targetH * scale) / 2.0
                    
                    var ctx = context
                    ctx.translateBy(x: offsetX, y: offsetY)
                    ctx.scaleBy(x: scale, y: scale)
                    ctx.opacity = Double(globalAlpha)
                    
                    // 1. S-STITCH MARK (Centered at X: 180, Y: 180, rotated 45°)
                    var markCtx = ctx
                    markCtx.translateBy(x: 180, y: 180)
                    markCtx.rotate(by: .degrees(45))
                    
                    let cap1Rect = CGRect(x: -72, y: -95, width: 66, height: 150)
                    let cap2Rect = CGRect(x: 6, y: -55, width: 66, height: 150)
                    let cap1Path = Path(roundedRect: cap1Rect, cornerRadius: 33)
                    let cap2Path = Path(roundedRect: cap2Rect, cornerRadius: 33)
                    
                    // Fill capsules
                    if cap1Fill > 0 {
                        var fCtx = markCtx
                        fCtx.opacity = Double(cap1Fill)
                        fCtx.fill(cap1Path, with: .color(.white))
                    }
                    if cap2Fill > 0 {
                        var fCtx = markCtx
                        fCtx.opacity = Double(cap2Fill)
                        fCtx.fill(cap2Path, with: .color(.white))
                    }
                    
                    // Stroke capsules
                    if cap1Draw > 0 {
                        let trimmed = cap1Path.trimmedPath(from: 0, to: cap1Draw)
                        markCtx.stroke(trimmed, with: .color(.white), lineWidth: 4.5)
                    }
                    if cap2Draw > 0 {
                        let trimmed = cap2Path.trimmedPath(from: 0, to: cap2Draw)
                        markCtx.stroke(trimmed, with: .color(.white), lineWidth: 4.5)
                    }
                    
                    // Black Stitch Cut line
                    if stitchDraw > 0 {
                        var stitchPath = Path()
                        let curX = -20.0 + (40.0 * stitchDraw)
                        stitchPath.move(to: CGPoint(x: -20, y: 0))
                        stitchPath.addLine(to: CGPoint(x: curX, y: 0))
                        markCtx.stroke(stitchPath, with: .color(.black), style: StrokeStyle(lineWidth: 7.5, lineCap: .round))
                    }
                    
                    // 2. BRAND TYPOGRAPHY ("CodeStitcher")
                    let font = Font.system(size: 96, weight: .bold, design: .default)
                    let text = Text("CodeStitcher").font(font).foregroundColor(.white)
                    
                    if textFill > 0 {
                        var tCtx = ctx
                        tCtx.opacity = Double(textFill)
                        tCtx.draw(text, at: CGPoint(x: 320 + 290, y: 212 - 40))
                    }
                    if textDraw > 0 && textFill < 1.0 {
                        var tCtx = ctx
                        tCtx.opacity = Double(textDraw)
                        tCtx.draw(text, at: CGPoint(x: 320 + 290, y: 212 - 40))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            finishSplash()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                animationStarted = true
                withAnimation(.linear(duration: 3.2)) {
                    animProgress = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                    finishSplash()
                }
            }
        }
    }
}
