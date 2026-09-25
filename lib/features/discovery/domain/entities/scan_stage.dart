/// Which phase a running scan is in, for the progress panel.
enum ScanStage {
  /// Reading the ARP table and listening for mDNS/SSDP announcements.
  gatheringCandidates,

  /// Probing hosts already known from ARP/mDNS/SSDP/earlier scans first.
  probingCandidates,

  /// Sweeping the queued chunks address by address.
  sweeping,

  finished;

  String get label => switch (this) {
    ScanStage.gatheringCandidates => 'ARP, mDNS ve SSDP adayları toplanıyor',
    ScanStage.probingCandidates => 'Bilinen adaylar yoklanıyor',
    ScanStage.sweeping => 'Alt ağlar taranıyor',
    ScanStage.finished => 'Bitti',
  };
}
