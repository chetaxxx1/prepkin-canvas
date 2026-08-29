import SwiftUI
import AppKit

// Renders the traced slime at the reference's exact bbox size (886x795)
// on a transparent background, one PNG per expression.

let bodyC = Color(red: 0x51 / 255, green: 0xCF / 255, blue: 0xA0 / 255)
let bellyC = Color(red: 0xB1 / 255, green: 0xED / 255, blue: 0xD4 / 255)
let inkC = Color(red: 0x10 / 255, green: 0x18 / 255, blue: 0x20 / 255)

let W: CGFloat = 886
let H: CGFloat = 795

struct SlimeRender: View {
    let face: [[[Double]]]
    var body: some View {
        ZStack {
            TracedShape(subpaths: SlimeArt.body).fill(bodyC)
            TracedShape(subpaths: SlimeArt.belly).fill(bellyC)
            TracedShape(subpaths: face).fill(inkC)
        }
        .frame(width: W, height: H)
    }
}

@main
struct Harness {
    @MainActor
    static func main() {
        let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        let faces: [(String, [[[Double]]])] = [
            ("idle", SlimeArt.faceIdle),
            ("deadpan", SlimeArt.faceDeadpan),
            ("judging", SlimeArt.faceJudging),
            ("delight", SlimeArt.faceDelight),
            ("sleep", SlimeArt.faceSleep),
        ]

        for (name, face) in faces {
            let renderer = ImageRenderer(content: SlimeRender(face: face))
            renderer.scale = 1
            guard let cg = renderer.cgImage else { fatalError("render failed: \(name)") }
            let rep = NSBitmapImageRep(cgImage: cg)
            guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png failed") }
            let url = URL(fileURLWithPath: "\(outDir)/swift-\(name).png")
            try! data.write(to: url)
            print("wrote \(url.path) \(cg.width)x\(cg.height)")
        }
    }
}
