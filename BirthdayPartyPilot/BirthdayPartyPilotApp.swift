//
//  BirthdayPartyPilotApp.swift
//  BirthdayPartyPilot
//
//  Created by Mansi Shah on 7/26/26.
//

import Foundation
import SwiftUI

@main
struct BirthdayPartyPilotApp: App {
    @StateObject private var agent: BirthdayAgent

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        let partyDate = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 24)
        ) ?? .now

        let context = PartyContext(
            childName: "Viyana",
            age: 7,
            partyDate: partyDate,
            theme: "K-Pop Demon Hunters",
            adultCount: 30,
            childCount: 25,
            venue: "Pump It Up, Santa Clara"
        )

        _agent = StateObject(
            wrappedValue: BirthdayAgent(
                context: context,
                planner: DeterministicBirthdayPlanner(),
                tool: MockPartyTool()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(agent: agent)
        }
    }
}
