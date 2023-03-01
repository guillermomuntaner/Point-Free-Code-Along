public enum CounterAction {
    case decreaseTapped
    case increaseTapped
}

public func counterReducer(state: inout Int, action: CounterAction) {
    switch action {
    case .decreaseTapped:
        state = max(0, state - 1)
    case .increaseTapped:
        state += 1
    }
}
