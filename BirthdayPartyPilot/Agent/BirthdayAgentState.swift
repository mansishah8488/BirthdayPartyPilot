enum BirthdayAgentState: Equatable {
    case idle
    case planning
    case reviewing
    case failed(String)
}
