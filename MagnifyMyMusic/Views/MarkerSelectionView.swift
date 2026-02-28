//
//  MarkerSelectionView.swift
//  MagnifyMyMusic
//
//  Created by Sujit Varadhan on 2/15/26.
//

import SwiftUI

private struct MarkerTypeOption: Identifiable {
    let id = UUID()
    let label: String
    let type: NavigationMarkerType
}

// TODO: Add assets and icons for each marker type
private let markerTypeOptions: [MarkerTypeOption] = [
    MarkerTypeOption(label: "Repeat Forward (||:)", type: .repeatForward),
    MarkerTypeOption(label: "Repeat Backward (:||)", type: .repeatBackward(times: 1)),
    MarkerTypeOption(label: "First Ending (1.)", type: .volta(numbers: [1])),
    MarkerTypeOption(label: "Second Ending (2.)", type: .volta(numbers: [2])),
    // TODO: Maintain some state of what are the current markers and which options are available
    MarkerTypeOption(label: "Final Ending", type: .finalVoltaEnd),
    MarkerTypeOption(label: "Segno", type: .segno(label: nil)),
    MarkerTypeOption(label: "Coda", type: .coda(label: nil)),
    MarkerTypeOption(label: "D.C.", type: .dacapo),
    MarkerTypeOption(label: "D.S.", type: .dalsegno(label: nil)),
    MarkerTypeOption(label: "To Coda", type: .tocoda(label: nil)),
    MarkerTypeOption(label: "Fine", type: .fine),
]

struct MarkerTypePickerView: View {
    @Bindable var document: SheetMusicDocument
    @Binding var selectedMarkerType: NavigationMarkerType?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(markerTypeOptions) { option in
                Button {
                    selectedMarkerType = option.type
                    dismiss()
                } label: {
                    Text(option.label)
                }
            }
            .navigationTitle("Add marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
