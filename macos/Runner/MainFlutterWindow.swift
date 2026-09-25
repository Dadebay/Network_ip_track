import Cocoa
import CoreLocation
import CoreWLAN
import FlutterMacOS
import Darwin
import Security

class MainFlutterWindow: NSWindow {
  private var keychainChannel: KeychainChannel?
  private var icmpChannel: IcmpChannel?
  private var workspaceChannel: FlutterMethodChannel?
  private var wifiChannel: WifiChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    keychainChannel = KeychainChannel(
      messenger: flutterViewController.engine.binaryMessenger)
    icmpChannel = IcmpChannel(
      messenger: flutterViewController.engine.binaryMessenger)
    wifiChannel = WifiChannel(
      messenger: flutterViewController.engine.binaryMessenger)
    workspaceChannel = FlutterMethodChannel(
      name: "network_monitor/workspace",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    workspaceChannel?.setMethodCallHandler { call, result in
      // Only a device's own web UI is ever opened: plain http(s) URLs.
      guard call.method == "openUrl",
        let text = call.arguments as? String,
        let url = URL(string: text),
        url.scheme == "http" || url.scheme == "https"
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(NSWorkspace.shared.open(url))
    }

    super.awakeFromNib()
  }
}

/// Nearby Wi-Fi networks from CoreWLAN, to tell which SSID an access point
/// on the LAN broadcasts. macOS reveals SSIDs and BSSIDs only to apps with
/// Location Services permission, so the first scan asks for it.
final class WifiChannel: NSObject, CLLocationManagerDelegate {
  private let channel: FlutterMethodChannel
  private let locationManager = CLLocationManager()
  private var pending: [FlutterResult] = []
  private let queue = DispatchQueue(label: "network_monitor.wifi", qos: .utility)

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "network_monitor/wifi", binaryMessenger: messenger)
    super.init()
    locationManager.delegate = self
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "scan", let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.scan(result: result)
    }
  }

  private var authorizationStatus: CLAuthorizationStatus {
    if #available(macOS 11.0, *) {
      return locationManager.authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }

  private func scan(result: @escaping FlutterResult) {
    if authorizationStatus == .notDetermined {
      pending.append(result)
      locationManager.requestWhenInUseAuthorization()
      return
    }
    performScan(result: result)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    flushPending()
  }

  func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {
    flushPending()
  }

  private func flushPending() {
    guard authorizationStatus != .notDetermined, !pending.isEmpty else { return }
    let waiting = pending
    pending = []
    for result in waiting {
      performScan(result: result)
    }
  }

  private func performScan(result: @escaping FlutterResult) {
    let status = authorizationStatus
    let authorized = status != .denied && status != .restricted && status != .notDetermined
    queue.async {
      var payload: [String: Any] = ["authorized": authorized]
      defer {
        let reply = payload
        DispatchQueue.main.async { result(reply) }
      }
      guard let iface = CWWiFiClient.shared().interface() else {
        payload["status"] = "noWifi"
        return
      }
      guard iface.powerOn() else {
        payload["status"] = "wifiOff"
        return
      }
      do {
        let networks = try iface.scanForNetworks(withSSID: nil)
        payload["networks"] = networks.map { network -> [String: Any] in
          var entry: [String: Any] = ["rssi": network.rssiValue]
          if let ssid = network.ssid { entry["ssid"] = ssid }
          if let bssid = network.bssid { entry["bssid"] = bssid }
          if let channel = network.wlanChannel { entry["channel"] = channel.channelNumber }
          return entry
        }
        payload["status"] = "ok"
      } catch {
        payload["status"] = "error"
        payload["message"] = error.localizedDescription
      }
      if let ssid = iface.ssid() { payload["currentSsid"] = ssid }
      if let bssid = iface.bssid() { payload["currentBssid"] = bssid }
    }
  }
}

/// Router credentials in the macOS Keychain, as generic-password items under
/// one service, keyed by the traffic provider id. The narrow surface —
/// read/write/delete one opaque value — is all Dart gets. Secret values are
/// never logged; errors carry only the OSStatus.
final class KeychainChannel {
  private static let service = "com.dadebay.networkMonitor.router-credentials"
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "network_monitor/keychain", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let account = args["account"] as? String, !account.isEmpty
    else {
      result(FlutterError(code: "bad_args", message: "account required", details: nil))
      return
    }
    switch call.method {
    case "read":
      read(account: account, result: result)
    case "write":
      guard let value = args["value"] as? String else {
        result(FlutterError(code: "bad_args", message: "value required", details: nil))
        return
      }
      write(account: account, value: value, result: result)
    case "delete":
      let status = SecItemDelete(baseQuery(account) as CFDictionary)
      if status == errSecSuccess || status == errSecItemNotFound {
        result(nil)
      } else {
        result(Self.error(status))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func baseQuery(_ account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: account,
    ]
  }

  private func read(account: String, result: FlutterResult) {
    var query = baseQuery(account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    switch status {
    case errSecSuccess:
      guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
        result(FlutterError(code: "keychain_error", message: "undecodable item", details: nil))
        return
      }
      result(value)
    case errSecItemNotFound:
      result(nil)
    default:
      result(Self.error(status))
    }
  }

  private func write(account: String, value: String, result: FlutterResult) {
    let data = Data(value.utf8)
    let update: [String: Any] = [kSecValueData as String: data]
    var status = SecItemUpdate(baseQuery(account) as CFDictionary, update as CFDictionary)
    if status == errSecItemNotFound {
      var add = baseQuery(account)
      add[kSecValueData as String] = data
      add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
      status = SecItemAdd(add as CFDictionary, nil)
    }
    result(status == errSecSuccess ? nil : Self.error(status))
  }

  private static func error(_ status: OSStatus) -> FlutterError {
    FlutterError(code: "keychain_error", message: "OSStatus \(status)", details: nil)
  }
}

/// ICMP echo from inside the app process, over an unprivileged
/// SOCK_DGRAM/IPPROTO_ICMP socket (as Apple's SimplePing does). Unlike
/// spawning /sbin/ping, this uses the app's own local-network access, so
/// it works under the App Sandbox. One request per call, no retries.
final class IcmpChannel {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(
    label: "network_monitor.icmp", qos: .utility, attributes: .concurrent)

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "network_monitor/icmp", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "ping",
        let args = call.arguments as? [String: Any],
        let ip = args["ip"] as? String,
        let timeoutMs = args["timeoutMs"] as? Int
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.queue.async {
        let reply = IcmpChannel.ping(ip: ip, timeoutMs: max(50, min(timeoutMs, 10000)))
        DispatchQueue.main.async { result(reply) }
      }
    }
  }

  /// {"ttl": Int, "rttMicros": Int} on a reply; {"errno": Int} when the
  /// request couldn't be sent; {} on timeout.
  static func ping(ip: String, timeoutMs: Int) -> [String: Int] {
    var target = sockaddr_in()
    target.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    target.sin_family = sa_family_t(AF_INET)
    guard inet_pton(AF_INET, ip, &target.sin_addr) == 1 else { return ["errno": Int(EINVAL)] }

    let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
    guard fd >= 0 else { return ["errno": Int(errno)] }
    defer { close(fd) }

    let identifier = UInt16.random(in: 1...UInt16.max)
    let sequence = UInt16.random(in: 1...UInt16.max)
    var packet: [UInt8] = [8, 0, 0, 0,
                           UInt8(identifier >> 8), UInt8(identifier & 0xFF),
                           UInt8(sequence >> 8), UInt8(sequence & 0xFF)]
    packet += Array("network_monitor!".utf8)
    let sum = checksum(packet)
    packet[2] = UInt8(sum >> 8)
    packet[3] = UInt8(sum & 0xFF)

    let started = DispatchTime.now()
    let sent = packet.withUnsafeBytes { bytes in
      withUnsafePointer(to: &target) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          sendto(fd, bytes.baseAddress, packet.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
      }
    }
    if sent < 0 { return ["errno": Int(errno)] }

    let deadline = started.uptimeNanoseconds + UInt64(timeoutMs) * 1_000_000
    var buffer = [UInt8](repeating: 0, count: 1500)
    while true {
      let now = DispatchTime.now().uptimeNanoseconds
      if now >= deadline { return [:] }
      let remaining = deadline - now
      var tv = timeval(tv_sec: Int(remaining / 1_000_000_000),
                       tv_usec: Int32((remaining % 1_000_000_000) / 1000))
      setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

      var from = sockaddr_in()
      var fromLength = socklen_t(MemoryLayout<sockaddr_in>.size)
      let received = withUnsafeMutablePointer(to: &from) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          recvfrom(fd, &buffer, buffer.count, 0, $0, &fromLength)
        }
      }
      if received < 0 {
        if errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR { continue }
        return ["errno": Int(errno)]
      }
      guard from.sin_addr.s_addr == target.sin_addr.s_addr else { continue }

      // macOS delivers the IP header with DGRAM ICMP; skip it if present.
      var offset = 0
      var ttl = -1
      if received >= 20, buffer[0] >> 4 == 4 {
        ttl = Int(buffer[8])
        offset = Int(buffer[0] & 0x0F) * 4
      }
      guard received >= offset + 8 else { continue }
      let type = buffer[offset]
      let seq = UInt16(buffer[offset + 6]) << 8 | UInt16(buffer[offset + 7])
      guard type == 0, seq == sequence else { continue }

      let rtt = (DispatchTime.now().uptimeNanoseconds - started.uptimeNanoseconds) / 1000
      var reply = ["rttMicros": Int(rtt)]
      if ttl >= 0 { reply["ttl"] = ttl }
      return reply
    }
  }

  private static func checksum(_ data: [UInt8]) -> UInt16 {
    var sum: UInt32 = 0
    var index = 0
    while index + 1 < data.count {
      sum += UInt32(data[index]) << 8 | UInt32(data[index + 1])
      index += 2
    }
    if index < data.count { sum += UInt32(data[index]) << 8 }
    while sum >> 16 != 0 { sum = (sum & 0xFFFF) + (sum >> 16) }
    return ~UInt16(sum)
  }
}
