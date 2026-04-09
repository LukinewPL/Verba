import Foundation

protocol TestAdvanceScheduling {
    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> DispatchWorkItem
}

struct MainQueueTestAdvanceScheduler: TestAdvanceScheduling {
    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }
}

struct ImmediateTestAdvanceScheduler: TestAdvanceScheduling {
    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: action)
        workItem.perform()
        return workItem
    }
}
