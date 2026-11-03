import SwiftUI

/// Menu bar icon. Kept to a plain symbol: animated content in a MenuBarExtra label makes SwiftUI
/// re-render the status item in a tight loop.
struct MenuBarLabel: View {
    let app: AppModel

    var body: some View {
        Image(systemName: symbol)
            .accessibilityLabel("Liddy")
    }

    private var symbol: String {
        if app.privacyShield.isActive { return "eye.slash.fill" }
        if app.calibration != nil { return "scope" }
        if !app.config.enabled { return "hand.raised.slash" }
        return app.tapFlash ? "hand.tap.fill" : "hand.tap"
    }
}

struct MenuPanel: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var app = app
        VStack(alignment: .leading, spacing: 0) {
            header(enabled: $app.config.enabled)
                .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)
            if let notice {
                noticeRow(notice).padding(.horizontal, 14).padding(.bottom, 10)
            }
            if app.isTrained {
                map.padding(.horizontal, 14)
                lastTap.padding(.horizontal, 14).padding(.top, 8)
            } else {
                firstRun.padding(.horizontal, 14)
            }
            motion.padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 12)
            privacyShield.padding(.horizontal, 14).padding(.bottom, 10)
            Divider().padding(.horizontal, 8)
            VStack(spacing: 0) {
                MenuRow(title: app.isTrained ? "Calibrate Again…" : "Calibrate…", symbol: "scope") { dismiss(); app.startCalibration() }
                MenuRow(title: "Settings…", symbol: "gearshape", shortcut: "⌘,") { dismiss(); app.showSettings() }
                    .keyboardShortcut(",", modifiers: .command)
                MenuRow(title: "Quit Liddy", symbol: "power", shortcut: "⌘Q") { NSApp.terminate(nil) }
                    .keyboardShortcut("q", modifiers: .command)
            }
            .padding(6)
        }
        .padding(.vertical, 8)
        .frame(width: 342)
        .background(DS.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .tint(DS.accent)
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private func header(enabled: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "rectangle.split.3x3.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 38, height: 38)
                .background(DS.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(DS.accent.opacity(0.2), lineWidth: 1))
            VStack(alignment: .leading, spacing: 5) {
                Text("Liddy")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                HStack(spacing: 6) {
                    Circle().fill(statusTint).frame(width: 6, height: 6)
                    Text(statusLine)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .contentTransition(.opacity)
                        .animation(DS.Motion.state, value: statusLine)
                }
            }
            Spacer(minLength: 8)
            Toggle("Liddy", isOn: enabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .help(app.config.enabled ? "Pause Liddy" : "Resume Liddy")
        }
    }

    private var statusTint: Color {
        if let error = app.status.error, !error.isEmpty { return .orange }
        if !app.config.enabled { return .secondary }
        if app.privacyShield.isActive { return DS.violet }
        if app.status.rate < 50 { return .orange }
        return DS.accent
    }

    private var statusLine: String {
        if let e = app.status.error, !e.isEmpty { return "Motion sensor unavailable" }
        if app.status.rate < 50 { return "Starting the motion sensor…" }
        if app.privacyShield.isActive { return "Privacy Shield is on" }
        if app.calibration != nil { return "Calibrating" }
        if !app.config.enabled { return "Paused" }
        if app.isTraining { return "Learning your taps…" }
        guard app.isTrained else { return "Not calibrated yet" }
        let acc = app.accuracy.map { " · \(Int(($0 * 100).rounded()))% accurate" } ?? ""
        return "Listening on \(app.grid.title)\(acc)"
    }

    // MARK: Notices

    private struct Notice { let symbol: String; let text: String; let button: String?; let action: (() -> Void)? }

    private var notice: Notice? {
        if let e = app.status.error, !e.isEmpty {
            return Notice(symbol: "exclamationmark.triangle.fill", text: e, button: nil, action: nil)
        }
        if !app.status.accessibility {
            return Notice(symbol: "hand.raised.fill", text: "To switch desktops and control music, allow Liddy in Accessibility.",
                          button: "Allow…", action: { Permissions.requestAccessibility(); Permissions.openPrivacyPane("Privacy_Accessibility") })
        }
        return nil
    }

    private func noticeRow(_ n: Notice) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: n.symbol).foregroundStyle(.orange)
            Text(n.text).font(.callout).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let b = n.button, let a = n.action { Button(b, action: a).controlSize(.small) }
        }
    }

    // MARK: Zones

    private var map: some View {
        DisplayMap(grid: app.grid, action: app.action(for:), style: .regular, ripple: app.ripple,
                   onSelect: { app.testAction(zone: $0) },
                   contextMenu: { zone in AnyView(ZoneActionMenu(zone: zone).environment(app)) })
    }

    @ViewBuilder
    private var lastTap: some View {
        HStack(spacing: 6) {
            if let r = app.lastRecord {
                Image(systemName: icon(r.outcome)).foregroundStyle(color(r.outcome))
                Text(describe(r)).lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 4)
                Text(r.date, style: .relative).foregroundStyle(.tertiary).monospacedDigit()
            } else {
                Text("Tap a zone on your screen, or click one here to try it.").foregroundStyle(.secondary)
            }
        }
        .font(.system(.caption, design: .rounded))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DS.elevated.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func describe(_ r: TapRecord) -> String {
        let zone = r.label.flatMap(zoneIndex).map { "Zone \($0 + 1)" }
        switch r.outcome {
        case .acted: return [zone, r.detail].compactMap { $0 }.joined(separator: " · ")
        case .rejected: return "Not sure which zone"
        case .ignored: return r.detail
        case .guarded: return "Ignored while Privacy Shield is on"
        case .recorded: return r.detail
        case .untrained: return "Tap felt. Calibrate to use it"
        }
    }

    private func icon(_ o: TapRecord.Outcome) -> String {
        switch o {
        case .acted: "checkmark.circle.fill"
        case .rejected: "questionmark.circle.fill"
        case .ignored, .guarded: "minus.circle.fill"
        case .recorded: "record.circle"
        case .untrained: "hand.tap"
        }
    }

    private func color(_ o: TapRecord.Outcome) -> Color {
        switch o {
        case .acted: .green
        case .rejected: .orange
        default: .secondary
        }
    }

    private var firstRun: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisplayMap(grid: app.grid, action: { _ in ZoneAction() }, style: .regular)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "hand.tap").font(.title2).foregroundStyle(.white.opacity(0.85))
                        Text("Your screen, split into zones").font(.callout.weight(.medium)).foregroundStyle(.white.opacity(0.85))
                    }
                    .allowsHitTesting(false)
                }
            Text("Calibrate once: tap each highlighted zone a few times. It takes about two minutes.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button { dismiss(); app.startCalibration() } label: {
                Text("Calibrate").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: Motion

    private var motion: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Motion").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Text(app.status.lid.map { "Lid \($0)°" } ?? "").font(.caption).foregroundStyle(.tertiary).monospacedDigit()
            }
            MotionTrace(detector: app.detector, seconds: 4).frame(height: 34)
        }
        .padding(10)
        .background(DS.elevated.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Privacy Shield

    private var privacyShield: some View {
        let on = app.privacyShield.isActive
        return Button { app.privacyShield.toggle() } label: {
            Label(on ? "Turn Off Privacy Shield" : "Privacy Shield", systemImage: on ? "eye" : "eye.slash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(ActionKind.privacyShield.tint)
        .controlSize(.large)
        .help("Mute every microphone, turn your meeting camera off and hide the screen")
    }
}

/// Right-click menu on a zone: reassign it in place.
struct ZoneActionMenu: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let zone: Int

    var body: some View {
        let current = app.action(for: zone).kind
        Text("Zone \(zone + 1)")
        ForEach(ActionKind.allCases.filter { $0 != .openApp }) { kind in
            Button {
                app.setAction(ZoneAction(kind: kind), for: zone)
            } label: {
                Label(kind.title, systemImage: current == kind ? "checkmark" : kind.symbol)
            }
        }
        Divider()
        Button("Open App…") { dismiss(); app.showSettings(pane: "zones", zone: zone) }
    }
}

/// A menu-style row: full width, highlights on hover like a menu item, with an optional shortcut.
struct MenuRow: View {
    let title: String
    let symbol: String
    var shortcut: String?
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).frame(width: 18).foregroundStyle(hover ? DS.accent : .secondary)
                Text(title)
                Spacer()
                if let shortcut { Text(shortcut).foregroundStyle(hover ? DS.accent : Color.secondary) }
            }
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8).padding(.vertical, 7)
            .background(hover ? DS.accent.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}
