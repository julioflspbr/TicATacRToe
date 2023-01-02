//
//  InterruptionController.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 27/12/2022.
//

import SwiftUI

final class InterruptionController: ObservableObject, GameControllerInterruptionDelegate, BroadcastControllerAlertDelegate, InformationControllerInterruptionDelegate {
    @MainActor @Published fileprivate var isDisplayingAlert: Bool = false {
        didSet {
            self.alert = (self.is3DInteractionDenied ? self.alert : nil)
        }
    }

    @MainActor @Published fileprivate private(set) var alert: InterruptingAlert.AlertContent?

    @MainActor @Published private var is3DInteractionDenied = true

    @MainActor var isInteractionBlocked: Bool {
        self.isDisplayingAlert || is3DInteractionDenied
    }

    @MainActor func allow3DInteraction() {
        self.is3DInteractionDenied = false
    }

    @MainActor func deny3DInteraction() {
        self.is3DInteractionDenied = true
    }

    @MainActor func handleError(_ error: Error) {
        self.showAlert(title: "Bummer", description: error.localizedDescription)
    }

    @MainActor func showAlert(title: String, description: String, actions: [InterruptingAlert.Action] = []) {
        self.alert = InterruptingAlert.AlertContent(title: title, description: description, actions: actions)
        self.isDisplayingAlert = true
    }
}

struct InterruptingAlert: ViewModifier {
    struct Action {
        let title: String
        let role: ButtonRole?
        let action: (() -> Void)

        init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
            self.title = title
            self.role = role
            self.action = action
        }
    }

    fileprivate struct AlertContent {
        let title: String
        let description: String
        let actions: [Action]
    }

    fileprivate init() {
        // making init inaccessible outside of the file
    }

    @EnvironmentObject private var interruptionController: InterruptionController

    func body(content: Content) -> some View {
        content.alert(
            self.interruptionController.alert?.title ?? "",
            isPresented: $interruptionController.isDisplayingAlert,
            presenting: self.interruptionController.alert,
            actions: { alert in
                ForEach(alert.actions, id: \.title) { action in
                    Button(action.title, role: action.role, action: action.action)
                }
            },
            message: { alert in
                Text(alert.description)
            }
        )
    }
}

extension View {
    func alertHandler() -> some View {
        self.modifier(InterruptingAlert())
    }
}
