import os

/// Unified logging. Query with: log show --predicate 'subsystem == "dev.liddy"' --info
enum Log {
    static let app = Logger(subsystem: "dev.liddy", category: "app")
    static let sensor = Logger(subsystem: "dev.liddy", category: "sensor")
    static let action = Logger(subsystem: "dev.liddy", category: "action")
}
