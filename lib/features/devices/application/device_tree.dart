import '../../../core/utils/cidr.dart';
import '../../../core/utils/private_network_blocks.dart';
import '../../network_scope/domain/entities/accessible_subnet.dart';
import '../../network_scope/domain/entities/subnet_reachability.dart';
import '../domain/entities/device.dart';
import '../domain/entities/device_type.dart';

/// Device groups shown under a subnet/gateway in the tree.
enum DeviceGroup {
  phones('Telefonlar'),
  tablets('Tabletler'),
  computers('Bilgisayarlar'),
  networkDevices('Ağ cihazları'),
  printers('Yazıcılar'),
  media('Medya cihazları'),
  iot('IoT'),
  consoles('Oyun konsolları'),
  cameras('Kameralar'),
  unknown('Bilinmeyen');

  const DeviceGroup(this.label);
  final String label;

  static DeviceGroup of(DeviceType type) => switch (type) {
    DeviceType.phone => phones,
    DeviceType.tablet => tablets,
    DeviceType.windowsComputer ||
    DeviceType.mac ||
    DeviceType.linuxComputerServer => computers,
    DeviceType.routerGateway => networkDevices,
    DeviceType.printer => printers,
    DeviceType.smartTvMedia => media,
    DeviceType.iotSmartHome => iot,
    DeviceType.gameConsole => consoles,
    DeviceType.camera => cameras,
    DeviceType.unknown => unknown,
  };
}

sealed class DeviceTreeNode {
  const DeviceTreeNode({required this.id, this.children = const []});

  /// Stable across rebuilds, so expand/collapse state survives new devices
  /// streaming in.
  final String id;
  final List<DeviceTreeNode> children;
}

/// `172.16.0.0/12 · Özel 172 ağı`.
class BlockTreeNode extends DeviceTreeNode {
  const BlockTreeNode({required this.cidr, super.children})
    : super(id: 'block:$cidr');
  final Cidr cidr;
}

class SubnetTreeNode extends DeviceTreeNode {
  const SubnetTreeNode({
    required this.cidr,
    required this.reachability,
    required this.deviceCount,
    super.children,
  }) : super(id: 'subnet:$cidr');

  final Cidr cidr;

  /// Null for subnets known only from earlier scans, with no current route.
  final SubnetReachability? reachability;
  final int deviceCount;
}

/// The gateway device, parenting the rest of its subnet like in the spec.
class GatewayTreeNode extends DeviceTreeNode {
  GatewayTreeNode({required this.device, super.children})
    : super(id: 'gateway:${device.id}');
  final Device device;
}

class GroupTreeNode extends DeviceTreeNode {
  GroupTreeNode({
    required String parentId,
    required this.group,
    required super.children,
  }) : super(id: '$parentId/group:${group.name}');

  final DeviceGroup group;
  int get count => children.length;
}

class DeviceLeafNode extends DeviceTreeNode {
  DeviceLeafNode(this.device) : super(id: 'device:${device.id}');
  final Device device;
}

/// Builds the spec's tree:
///
/// ```text
/// 172.16.0.0/12 · Özel 172 ağı
/// ├── 172.16.14.0/24 · Doğrudan bağlı
/// │   └── Gateway · 172.16.14.254
/// │       ├── Telefonlar (3)
/// │       └── Bilinmeyen (2)
/// └── 172.20.0.0/16 · Erişilemiyor
/// ```
///
/// [devices] is expected already filtered and sorted; that order is kept
/// inside each group. Route-table subnets always appear (they are scope
/// information); subnets known only from device history appear when they
/// have matching devices. Subnets outside `172.16.0.0/12` (e.g. a home
/// `192.168.1.0/24` scanned via "Bu alt ağı tara") become top-level nodes.
List<DeviceTreeNode> buildDeviceTree({
  required List<Device> devices,
  required List<AccessibleSubnet> subnets,
  Cidr? activeSubnet,
}) {
  final subnetInfo = <Cidr, SubnetReachability?>{
    for (final subnet in subnets) subnet.cidr: subnet.reachability,
  };
  if (activeSubnet != null) {
    subnetInfo.putIfAbsent(
      activeSubnet,
      () => SubnetReachability.directlyConnected,
    );
  }

  // Most specific matching subnet wins; unmatched devices fall back to
  // their /24.
  final orderedSubnets = subnetInfo.keys.toList()
    ..sort((a, b) => b.prefixLength.compareTo(a.prefixLength));
  final devicesBySubnet = <Cidr, List<Device>>{};
  for (final device in devices) {
    final subnet = orderedSubnets.firstWhere(
      (cidr) => cidr.contains(device.currentIp),
      orElse: () => Cidr.fromAddressAndPrefix(device.currentIp, 24),
    );
    subnetInfo.putIfAbsent(subnet, () => null);
    (devicesBySubnet[subnet] ??= []).add(device);
  }

  final subnetNodes = [
    for (final cidr
        in subnetInfo.keys.toList()
          ..sort((a, b) => a.networkAddress.compareTo(b.networkAddress)))
      _subnetNode(cidr, subnetInfo[cidr], devicesBySubnet[cidr] ?? const []),
  ];

  final inBlock = [
    for (final node in subnetNodes)
      if (isWithinPrivate172Block(node.cidr)) node,
  ];
  final outsideBlock = [
    for (final node in subnetNodes)
      if (!isWithinPrivate172Block(node.cidr)) node,
  ];

  return [
    if (inBlock.isNotEmpty)
      BlockTreeNode(cidr: private172Block, children: inBlock),
    ...outsideBlock,
  ];
}

SubnetTreeNode _subnetNode(
  Cidr cidr,
  SubnetReachability? reachability,
  List<Device> devices,
) {
  final gateway = devices.where((device) => device.isGateway).firstOrNull;
  final others = [
    for (final device in devices)
      if (!identical(device, gateway)) device,
  ];
  final subnetId = 'subnet:$cidr';

  List<DeviceTreeNode> groups(String parentId) {
    final byGroup = <DeviceGroup, List<DeviceTreeNode>>{};
    for (final device in others) {
      (byGroup[DeviceGroup.of(device.effectiveType)] ??= []).add(
        DeviceLeafNode(device),
      );
    }
    return [
      for (final group in DeviceGroup.values)
        if (byGroup[group] case final children?)
          GroupTreeNode(parentId: parentId, group: group, children: children),
    ];
  }

  return SubnetTreeNode(
    cidr: cidr,
    reachability: reachability,
    deviceCount: devices.length,
    children: gateway == null
        ? groups(subnetId)
        : [
            GatewayTreeNode(
              device: gateway,
              children: groups('gateway:${gateway.id}'),
            ),
          ],
  );
}

/// One visible row of the flattened tree.
class DeviceTreeRow {
  const DeviceTreeRow({
    required this.node,
    required this.depth,
    required this.isExpanded,
    this.parentId,
  });

  final DeviceTreeNode node;
  final int depth;
  final bool isExpanded;

  /// Null for a root. Lets the tree view jump focus to a row's parent
  /// (keyboard ←) without re-walking the tree.
  final String? parentId;

  bool get hasChildren => node.children.isNotEmpty;
}

/// Whether [node] starts expanded, before any user toggle. Blocks, subnets
/// and gateways start open — there are only a handful of them even in a
/// large scan. Groups start closed: with hundreds of devices, opening every
/// group by default would dump the whole scan onto the screen at once.
bool isExpandedByDefault(DeviceTreeNode node) => node is! GroupTreeNode;

/// Flattens [roots] into the rows currently visible, so the view can be a
/// lazily built (virtualized) list regardless of device count.
///
/// A node's expansion is [isExpandedByDefault] unless its id is in
/// [toggled], which flips it — so the caller only ever needs to remember
/// what the user actually clicked, not the full expanded set. [forceExpanded]
/// overrides both, ignoring the toggle: pass every node id in the tree while
/// a search/filter is active so a match is never left hidden inside a
/// collapsed group.
List<DeviceTreeRow> flattenDeviceTree(
  List<DeviceTreeNode> roots,
  Set<String> toggled, {
  Set<String> forceExpanded = const {},
}) {
  final rows = <DeviceTreeRow>[];
  void visit(DeviceTreeNode node, int depth, String? parentId) {
    final defaultExpanded = isExpandedByDefault(node);
    final expanded =
        forceExpanded.contains(node.id) ||
        (toggled.contains(node.id) ? !defaultExpanded : defaultExpanded);
    rows.add(
      DeviceTreeRow(
        node: node,
        depth: depth,
        isExpanded: expanded,
        parentId: parentId,
      ),
    );
    if (!expanded) return;
    for (final child in node.children) {
      visit(child, depth + 1, node.id);
    }
  }

  for (final root in roots) {
    visit(root, 0, null);
  }
  return rows;
}

/// Every node id in [roots] — used to build [flattenDeviceTree]'s
/// `forceExpanded` set while a search/filter is active. The device list
/// feeding [buildDeviceTree] is already filtered by then, so every group
/// still in the tree contains only matches and should be forced open rather
/// than left collapsed behind its type default.
Set<String> allTreeNodeIds(List<DeviceTreeNode> roots) {
  final ids = <String>{};
  void visit(DeviceTreeNode node) {
    ids.add(node.id);
    for (final child in node.children) {
      visit(child);
    }
  }

  for (final root in roots) {
    visit(root);
  }
  return ids;
}
