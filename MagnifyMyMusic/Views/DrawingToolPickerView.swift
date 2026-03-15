//
//  DrawingToolPickerView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit

struct DrawingToolPickerView: View {
    @Binding var currentTool: PKTool
    @Environment(\.dismiss) var dismiss

    @State private var lastInkingTool: PKInkingTool
    @State private var isEraser: Bool

    let colors: [UIColor] = [.red, .blue, .green, .black, .orange, .purple, .brown, .systemPink]
    let widths: [CGFloat] = [20, 40, 60, 80]

    init(currentTool: Binding<PKTool>) {
        self._currentTool = currentTool
        if let inkingTool = currentTool.wrappedValue as? PKInkingTool {
            self._lastInkingTool = State(wrappedValue: inkingTool)
            self._isEraser = State(wrappedValue: false)
        } else {
            self._lastInkingTool = State(wrappedValue: PKInkingTool(.pen, color: AppTheme.defaultDrawingColor,  width: AppTheme.defaultDrawingWidth))
            self._isEraser = State(wrappedValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 24) {
                // Color section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.headline)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            let colorSelected = lastInkingTool.color == color && !isEraser
                            Circle()
                                .fill(Color(color))
                                .frame(width: 44, height: 44)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorSelected ? Color.white : Color.clear)
                                )
                                .onTapGesture {
                                    lastInkingTool = PKInkingTool(
                                        .pen,
                                        color: color,
                                        width: lastInkingTool.width
                                    )
                                    isEraser = false
                                    currentTool = lastInkingTool
                                }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Width section with squiggle icons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Width")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(widths, id: \.self) { width in
                            let isSelected = lastInkingTool.width == width && !isEraser
                            let displayWidth = width / 10  // Scale down for icon display
                            Button {
                                lastInkingTool = PKInkingTool(
                                    .pen,
                                    color: lastInkingTool.color,
                                    width: width
                                )
                                isEraser = false
                                currentTool = lastInkingTool
                                dismiss()
                            } label: {
                                SquiggleShape()
                                    .stroke(Color(lastInkingTool.color), lineWidth: displayWidth)
                                    .frame(width: 44, height: 44)
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? Color.white : Color.clear)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Eraser button
                Button {
                    isEraser = true
                    currentTool = PKEraserTool(.bitmap)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "eraser.fill")
                        Text("Eraser")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isEraser ? Color.blue : Color(.systemGray6))
                    .foregroundColor(isEraser ? .white : .primary)
                    .cornerRadius(12)
                }

            }
            .padding()
            }
            .navigationTitle("Drawing Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// A short S-curve shape used as a thickness icon
struct SquiggleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let startX = rect.minX + 4
        let endX = rect.maxX - 4
        let amplitude: CGFloat = rect.height * 0.25

        path.move(to: CGPoint(x: startX, y: midY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: midY),
            control1: CGPoint(x: startX + (endX - startX) * 0.2, y: midY - amplitude),
            control2: CGPoint(x: startX + (endX - startX) * 0.35, y: midY - amplitude)
        )
        path.addCurve(
            to: CGPoint(x: endX, y: midY),
            control1: CGPoint(x: startX + (endX - startX) * 0.65, y: midY + amplitude),
            control2: CGPoint(x: startX + (endX - startX) * 0.8, y: midY + amplitude)
        )
        return path
    }
}
