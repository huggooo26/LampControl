import Foundation

@MainActor
final class AutomationScheduler {
    var onFire: ((Automation) -> Void)?

    private var timer: Timer?
    private var automations: [Automation] = []
    private let calendar = Calendar.current

    func start(with automations: [Automation]) {
        self.automations = automations
        stop()
        guard automations.contains(where: \.isEnabled) else { return }

        // Align to next minute boundary for accuracy
        let now = Date()
        let nextMinute = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
        let delay = nextMinute.timeIntervalSinceNow

        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delay)) { [weak self] in
            guard let self else { return }
            self.tick()
            self.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func update(automations: [Automation]) {
        self.automations = automations
        if automations.contains(where: \.isEnabled) {
            if timer == nil { start(with: automations) }
        } else {
            stop()
        }
    }

    private func tick() {
        let now = Date()
        let minuteOfNow = calendar.dateComponents([.hour, .minute], from: now)
        for automation in automations where automation.isEnabled {
            // Avoid double-fire within same minute
            if let last = automation.lastFiredDate,
               calendar.isDate(last, equalTo: now, toGranularity: .minute) { continue }
            if automation.shouldFire(at: now, calendar: calendar) {
                onFire?(automation)
            }
        }
    }
}
