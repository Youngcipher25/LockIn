//
//  PermissionsView.swift
//  LockIn
//
//  Created by Admin on 06/03/26.
//

import SwiftUI

struct PermissionsView: View {

    @State private var notifications = true
    @State private var backgroundReminders = false

    var body: some View {

        Form {

            Toggle("Notifications", isOn: $notifications)

            Toggle("Background Reminders", isOn: $backgroundReminders)

            Text("You can revoke permissions anytime from device settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)

        }
        .navigationTitle("Permissions")
    }
}

#Preview("Permissions Page") {
    NavigationStack {
        PermissionsView()
    }
}
