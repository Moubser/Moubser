import 'dart:collection';
import '../data/models/map_node.dart';
import '../data/models/map_edge.dart';

/// Pure graph data structure + Dijkstra algorithm.
/// No network calls, no UI – purely computational.
class NavigationGraphService {
  final Map<int, MapNode> nodes = {};
  final Map<int, List<MapEdge>> adjacency = {};

  bool get isEmpty => nodes.isEmpty;

  /// Build the graph from fetched nodes and edges.
  void buildGraph(List<MapNode> nodeList, List<MapEdge> edgeList) {
    nodes.clear();
    adjacency.clear();

    for (final node in nodeList) {
      nodes[node.nodeId] = node;
      adjacency[node.nodeId] = [];
    }

    for (final edge in edgeList) {
      // Add both directions (undirected graph).
      if (adjacency.containsKey(edge.fromNode)) {
        adjacency[edge.fromNode]!.add(edge);
      }
      if (adjacency.containsKey(edge.toNode)) {
        adjacency[edge.toNode]!.add(MapEdge(
          edgeId: edge.edgeId,
          fromNode: edge.toNode,
          toNode: edge.fromNode,
          weight: edge.weight,
          isAccessible: edge.isAccessible,
        ));
      }
    }
  }

  /// Find the entrance / start node (node_type == 'entrance').
  /// Falls back to the first node if no entrance is marked.
  MapNode? findEntrance() {
    final entrance = nodes.values.cast<MapNode?>().firstWhere(
          (n) => n!.nodeType == 'entrance',
          orElse: () => nodes.values.isNotEmpty ? nodes.values.first : null,
        );
    return entrance;
  }

  /// Find the node that matches a given classroom label.
  MapNode? findNodeByLabel(String label) {
    return nodes.values.cast<MapNode?>().firstWhere(
          (n) => n!.label == label,
          orElse: () => null,
        );
  }

  /// Dijkstra shortest-path algorithm.
  /// Returns an ordered list of MapNode from start to end (inclusive).
  /// Returns empty list if no path exists.
  List<MapNode> dijkstra(int startId, int endId) {
    if (!nodes.containsKey(startId) || !nodes.containsKey(endId)) return [];
    if (startId == endId) return [nodes[startId]!];

    final Map<int, double> dist = {};
    final Map<int, int?> prev = {};
    final Set<int> visited = {};

    for (final id in nodes.keys) {
      dist[id] = double.infinity;
      prev[id] = null;
    }
    dist[startId] = 0;

    final queue = SplayTreeSet<int>((a, b) {
      int cmp = dist[a]!.compareTo(dist[b]!);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
    queue.add(startId);

    while (queue.isNotEmpty) {
      final u = queue.first;
      queue.remove(u);

      if (u == endId) break;
      if (visited.contains(u)) continue;
      visited.add(u);

      for (final edge in adjacency[u] ?? <MapEdge>[]) {
        final alt = dist[u]! + edge.weight;
        if (alt < dist[edge.toNode]!) {
          queue.remove(edge.toNode);
          dist[edge.toNode] = alt;
          prev[edge.toNode] = u;
          queue.add(edge.toNode);
        }
      }
    }

    // Reconstruct path
    final List<MapNode> path = [];
    int? current = endId;
    while (current != null) {
      if (nodes.containsKey(current)) {
        path.insert(0, nodes[current]!);
      }
      current = prev[current];
    }

    if (path.isEmpty || path.first.nodeId != startId) return [];
    return path;
  }

  /// Compute the total distance along a path.
  double totalPathDistance(List<MapNode> path) {
    double total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      total += path[i].distanceTo(path[i + 1]);
    }
    return total;
  }
}
