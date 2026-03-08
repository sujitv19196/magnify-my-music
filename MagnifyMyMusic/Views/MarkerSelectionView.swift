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
    MarkerTypeOption(label: "Start of Repeat (||:)", type: .repeatForward),
    MarkerTypeOption(label: "End of Simple Repeat (:||)", type: .repeatBackward(times: 1)),
    MarkerTypeOption(label: "Start of 1st/2nd Ending", type: .volta(numbers: [1])),
    // TODO: Maintain some state of what are the current markers and which options are available
    MarkerTypeOption(label: "End of Final Ending", type: .finalVoltaEnd),
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
                        .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Add Marker")
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
