//
//  InterruptionController.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 27/12/2022.
//

import SwiftUI

final class InterruptionController: ObservableObject, GameControllerInterruptionDelegate {
    @Published var shouldPresentAlert: Bool = false {
        didSet {
            self.is3DInteractionDenied = self.shouldPresentAlert
            self.alert = (self.is3DInteractionDenied ? self.alert : nil)
        }
    }

    @Published private(set) var is3DInteractionDenied = true

    @Published fileprivate private(set) var alert: InterruptingAlert.AlertContent?

    func allow3DInteraction() {
        self.is3DInteractionDenied = false
    }

    func deny3DInteraction() {
        self.is3DInteractionDenied = true
    }

    func handleError(_ error: Error) {
        self.showAlert(title: "Error", description: error.localizedDescription)
    }

    func showAlert(title: String, description: String, actions: [InterruptingAlert.Action] = []) {
        self.alert = InterruptingAlert.AlertContent(title: title, description: description, actions: actions)
        self.shouldPresentAlert = true
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
            isPresented: $interruptionController.shouldPresentAlert,
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
