import '../entities/route_entry.dart';

/// Platform adapter contract for reading the OS IPv4 route table.
abstract interface class RouteProvider {
  Future<List<RouteEntry>> getRouteTable();
}
