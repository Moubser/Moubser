import 'dart:math';

class MapNode {
  final int nodeId;
  final int? buildingId;
  final String label;
  final double x;
  final double y;
  final int floorNumber;
  final String nodeType;

  const MapNode({
    required this.nodeId,
    this.buildingId,
    required this.label,
    required this.x,
    required this.y,
    this.floorNumber = 0,
    this.nodeType = 'waypoint',
  });

  factory MapNode.fromJson(Map<String, dynamic> json) {
    return MapNode(
      nodeId: json['node_id'] as int,
      buildingId: json['building_id'] as int?,
      label: (json['label'] as String?) ?? '',
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      floorNumber: (json['floor_number'] as int?) ?? 0,
      nodeType: (json['node_type'] as String?) ?? 'waypoint',
    );
  }

  /// Euclidean distance to another node (used for bearing/direction calculations).
  double distanceTo(MapNode other) {
    return sqrt(pow(other.x - x, 2) + pow(other.y - y, 2));
  }

  /// Bearing angle in degrees from this node to another (0=North/Up, 90=East/Right).
  double bearingTo(MapNode other) {
    double dx = other.x - x;
    double dy = other.y - y;
    double radians = atan2(dx, -dy); // North-referenced
    double degrees = radians * 180 / pi;
    return (degrees + 360) % 360;
  }
}
