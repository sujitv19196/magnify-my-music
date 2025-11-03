//
//  DrawingToolPickerView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 11/1/25.
//

import SwiftUI
import PencilKit

struct DrawingToolPickerView: View {
    @Binding var currentTool: PKInkingTool
    @Environment(\.dismiss) var dismiss
    
    @State private var showEraser = false
    
    let colors: [UIColor] = [.red, .blue, .green, .black, .orange, .purple, .brown, .systemPink]
    let widths: [CGFloat] = [1, 2, 3, 5]
    let types: [PKInkingTool.InkType] = [.pen, .pencil, .marker]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tool Type")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(types, id: \.self) { type in
                            Button {
                                currentTool = PKInkingTool(
                                    type,
                                    color: currentTool.color,
                                    width: currentTool.width
                                )
                                showEraser = false
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
                                    currentTool.inkType == type && !showEraser
                                        ? Color.blue.opacity(0.2)
                                        : Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .foregroundColor(
                                currentTool.inkType == type && !showEraser ? .blue : .primary
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
                                        currentTool.color == color && !showEraser
                                            ? Color.blue
                                            : Color.clear,
                                        lineWidth: 3
                                    )
                                )
                                .onTapGesture {
                                    currentTool = PKInkingTool(
                                        currentTool.inkType,
                                        color: color,
                                        width: currentTool.width
                                    )
                                    showEraser = false
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
                                .frame(width: width * 10, height: width * 10)
                                .overlay(
                                    Circle().strokeBorder(
                                        currentTool.width == width && !showEraser
                                            ? Color.blue
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    currentTool = PKInkingTool(
                                        currentTool.inkType,
                                        color: currentTool.color,
                                        width: width
                                    )
                                    showEraser = false
                                }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button {
                    showEraser = true
                } label: {
                    HStack {
                        Image(systemName: "eraser.fill")
                        Text("Eraser")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showEraser ? Color.blue : Color(.systemGray6))
                    .foregroundColor(showEraser ? .white : .primary)
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
        .presentationDetents([.medium, .large])
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

