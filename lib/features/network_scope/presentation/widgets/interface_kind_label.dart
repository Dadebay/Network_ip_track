import 'package:hugeicons/hugeicons.dart';

import '../../domain/entities/interface_kind.dart';

extension InterfaceKindLabel on InterfaceKind {
  String get label => switch (this) {
    InterfaceKind.wifi => 'Wi-Fi',
    InterfaceKind.ethernet => 'Ethernet',
    InterfaceKind.loopback => 'Loopback',
    InterfaceKind.vpn => 'VPN',
    InterfaceKind.bridge => 'Bridge',
    InterfaceKind.virtual => 'Sanal',
    InterfaceKind.other => 'Diğer',
  };

  List<List<dynamic>> get icon => switch (this) {
    InterfaceKind.wifi => HugeIcons.strokeRoundedWifi01,
    InterfaceKind.ethernet => HugeIcons.strokeRoundedComputerEthernet,
    InterfaceKind.loopback => HugeIcons.strokeRoundedReload,
    InterfaceKind.vpn => HugeIcons.strokeRoundedShieldKey,
    InterfaceKind.bridge => HugeIcons.strokeRoundedGitBranch,
    InterfaceKind.virtual => HugeIcons.strokeRoundedLayers01,
    InterfaceKind.other => HugeIcons.strokeRoundedComputer,
  };
}
