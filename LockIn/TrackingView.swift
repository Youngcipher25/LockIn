//
//  TrackingView.swift
//  LockIn
//
//  Created by Admin on 06/03/26.
//

import SwiftUI

struct TrackingView: View {

    @State private var analytics = false
    @State private var crashReports = false

    var body: some View {

        Form {

            Toggle("Usage Analytics", isOn: $analytics)

            Toggle("Crash Reporting", isOn: $crashReports)

            Text("This application is designed with privacy as the default.")
                .font(.footnote)
                .foregroundStyle(.secondary)

        }
        .navigationTitle("Tracking")
    }
}

#Preview("Tracking Settings") {
    NavigationStack {
        TrackingView()
    }
}
