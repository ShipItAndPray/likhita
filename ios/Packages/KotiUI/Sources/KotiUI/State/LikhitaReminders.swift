import Foundation
import UserNotifications
import KotiCore

/// Local notification scheduler for the Pace screen's reminder slots.
/// Requests permission lazily (first call). Re-issues a fresh schedule
/// every time the user changes their selection — old reminders are
/// removed first, then the chosen ones are installed as daily-repeating
/// `UNNotificationRequest`s.
///
/// Slot id → (hour, minute) is canonical:
///   brahma   04:30  "The hour before dawn is yours."
///   pratah   07:00  "Good morning. Mantras await."
///   madhyana 12:30  "A few minutes between meetings."
///   sandhya  19:00  "Evening light. Close the day."
public enum LikhitaReminders {
    public struct Slot: Sendable {
        public let id: String
        public let hour: Int
        public let minute: Int
        public let title: String
        public let body: String
    }

    public static func slots(tradition: Tradition) -> [Slot] {
        let appName = tradition == .telugu ? "Likhita Rama" : "Likhita Ram"
        return [
            Slot(id: "brahma",   hour: 4,  minute: 30,
                 title: appName,
                 body: "The hour before dawn is yours."),
            Slot(id: "pratah",   hour: 7,  minute: 0,
                 title: appName,
                 body: "Good morning. Your koti awaits."),
            Slot(id: "madhyana", hour: 12, minute: 30,
                 title: appName,
                 body: "A few minutes between meetings."),
            Slot(id: "sandhya",  hour: 19, minute: 0,
                 title: appName,
                 body: "Evening light. Close the day."),
        ]
    }

    /// Request notification permission if not already determined. Returns
    /// true if authorized after the call. Idempotent — safe to call on
    /// every reschedule.
    public static func ensureAuthorized() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    /// Replace the current reminder schedule with one daily-repeating
    /// request per enabled slot. `slotIds` is the user's chosen subset
    /// of {brahma, pratah, madhyana, sandhya}, at most 3.
    public static func reschedule(slots slotIds: [String], tradition: Tradition) async {
        let center = UNUserNotificationCenter.current()
        // Drop any reminder we previously installed. We use a stable
        // prefix on identifiers so this never touches notifications
        // installed by anything else.
        let pending = await center.pendingNotificationRequests()
        let ours = pending.filter { $0.identifier.hasPrefix("likhita.reminder.") }
        center.removePendingNotificationRequests(
            withIdentifiers: ours.map(\.identifier)
        )

        guard await ensureAuthorized() else { return }

        for slot in slots(tradition: tradition) where slotIds.contains(slot.id) {
            var trigger = DateComponents()
            trigger.hour = slot.hour
            trigger.minute = slot.minute
            let content = UNMutableNotificationContent()
            content.title = slot.title
            content.body = slot.body
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "likhita.reminder.\(slot.id)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )
            try? await center.add(request)
        }
    }
}
