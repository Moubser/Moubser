class MapEdge {
  final int edgeId;
  final int fromNode;
  final int toNode;
  final double weight;
  final bool isAccessible;

  const MapEdge({
    required this.edgeId,
    required this.fromNode,
    required this.toNode,
    required this.weight,
    this.isAccessible = true,
  });

  factory MapEdge.fromJson(Map<String, dynamic> json) {
    return MapEdge(
      edgeId: json['edge_id'] as int,
      fromNode: json['from_node'] as int,
      toNode: json['to_node'] as int,
      weight: (json['weight'] as num).toDouble(),
      isAccessible: (json['is_accessible'] as bool?) ?? true,
    );
  }
}
