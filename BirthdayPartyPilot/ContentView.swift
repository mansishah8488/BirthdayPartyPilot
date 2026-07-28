//
//  ContentView.swift
//  BirthdayPartyPilot
//
//  Created by Mansi Shah on 7/26/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var agent: BirthdayAgent

    var body: some View {
        VStack(spacing: 0) {
            Text("Birthday Party Pilot")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            switch agent.state {
            case .idle, .planning:
                PartyBriefView(
                    context: agent.context,
                    isPlanning: agent.state == .planning,
                    onCreatePlan: {
                        Task {
                            await agent.start()
                        }
                    }
                )
            case .reviewing:
                PlanReviewView(
                    tasks: agent.tasks,
                    isApproved: { agent.isApproved(taskID: $0) },
                    canExecutePlan: agent.canExecutePlan,
                    onApprove: { taskID in
                        Task {
                            await agent.approve(taskID: taskID)
                        }
                    },
                    onExecutePlan: {
                        Task {
                            await agent.executePlan()
                        }
                    }
                )
            case .awaitingApproval, .executing, .completed, .failed:
                ExecutionView(
                    currentTask: agent.currentTask,
                    completedTasks: agent.completedTasks,
                    executionLog: agent.executionLog,
                    failureMessage: agent.failureMessage,
                    isComplete: agent.state == .completed,
                    canRetry: agent.failureMessage != nil && agent.currentTask != nil,
                    canApprove: canRespondToCurrentApproval,
                    canDecline: canRespondToCurrentApproval,
                    canRestart: agent.canRestart,
                    onRetry: {
                        Task {
                            await agent.retryFailedTask()
                        }
                    },
                    onApprove: {
                        guard let taskID = agent.currentTask?.id else {
                            return
                        }

                        Task {
                            await agent.approve(taskID: taskID)
                        }
                    },
                    onDecline: {
                        guard let taskID = agent.currentTask?.id else {
                            return
                        }

                        Task {
                            await agent.decline(taskID: taskID)
                        }
                    },
                    onRestart: {
                        agent.restart()
                    }
                )
            }
        }
    }

    private var canRespondToCurrentApproval: Bool {
        guard case let .awaitingApproval(taskID) = agent.state,
              let currentTask = agent.currentTask
        else {
            return false
        }

        return currentTask.id == taskID
            && currentTask.approvalRequirement == .required
            && currentTask.status == .awaitingApproval
    }
}
