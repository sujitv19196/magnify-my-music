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

    // Track the last inking tool so we can restore it when switching away from eraser
    @State private var lastInkingTool: PKInkingTool
    @State private var isEraser: Bool

    let colors: [UIColor] = [.red, .blue, .green, .black, .orange, .purple, .brown, .systemPink]
    let widths: [CGFloat] = [2, 5, 10, 20]
    let types: [PKInkingTool.InkType] = [.pen, .pencil, .marker]

    init(currentTool: Binding<PKTool>) {
        self._currentTool = currentTool
        if let inkingTool = currentTool.wrappedValue as? PKInkingTool {
            self._lastInkingTool = State(wrappedValue: inkingTool)
            self._isEraser = State(wrappedValue: false)
        } else {
            self._lastInkingTool = State(wrappedValue: PKInkingTool(.pen, color: .red, width: 2))
            self._isEraser = State(wrappedValue: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tool Type")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(types, id: \.self) { type in
                            Button {
                                lastInkingTool = PKInkingTool(
                                    type,
                                    color: lastInkingTool.color,
                                    width: lastInkingTool.width
                                )
                                isEraser = false
                                currentTool = lastInkingTool
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: icon(for: type))
                                        .font(.title)
                                    Text(name(for: type))
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    lastInkingTool.inkType == type && !isEraser
                                        ? Color.blue.opacity(0.2)
                                        : Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .foregroundColor(
                                lastInkingTool.inkType == type && !isEraser ? .blue : .primary
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle().strokeBorder(
                                        lastInkingTool.color == color && !isEraser
                                            ? Color.blue
                                            : Color.clear,
                                        lineWidth: 3
                                    )
                                )
                                .onTapGesture {
                                    lastInkingTool = PKInkingTool(
                                        lastInkingTool.inkType,
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
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Width")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(widths, id: \.self) { width in
                            Circle()
                                .fill(Color.black)
                                .frame(width: max(10, width * 3), height: max(10, width * 3))
                                .overlay(
                                    Circle().strokeBorder(
                                        lastInkingTool.width == width && !isEraser
                                            ? Color.blue
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    lastInkingTool = PKInkingTool(
                                        lastInkingTool.inkType,
                                        color: lastInkingTool.color,
                                        width: width
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
                
                Button {
                    isEraser = true
                    currentTool = PKEraserTool(.bitmap)
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("Drawing Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func icon(for type: PKInkingTool.InkType) -> String {
        switch type {
        case .pen: return "pencil"
        case .pencil: return "pencil.tip"
        case .marker: return "highlighter"
        default: return "pencil"
        }
    }
    
    private func name(for type: PKInkingTool.InkType) -> String {
        switch type {
        case .pen: return "Pen"
        case .pencil: return "Pencil"
        case .marker: return "Marker"
        default: return "Pen"
        }
    }
}

