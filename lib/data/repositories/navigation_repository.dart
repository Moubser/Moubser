import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/map_node.dart';
import '../models/map_edge.dart';

/// Repository responsible for fetching navigation graph data from Supabase.
class NavigationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all navigation nodes for a specific building.
  Future<List<MapNode>> fetchNodesByBuilding(int buildingId) async {
    final data = await _client
        .from('nav_nodes')
        .select()
        .eq('building_id', buildingId);
    return data.map<MapNode>((json) => MapNode.fromJson(json)).toList();
  }

  /// Fetch all edges that connect nodes within the given node set.
  Future<List<MapEdge>> fetchEdgesForNodes(List<int> nodeIds) async {
    if (nodeIds.isEmpty) return [];
    final data = await _client
        .from('nav_edges')
        .select()
        .inFilter('from_node', nodeIds);
    return data
        .map<MapEdge>((json) => MapEdge.fromJson(json))
        .where((e) => e.isAccessible)
        .toList();
  }

  /// Fetch all destinations (using classrooms table since buildings is empty).
  Future<List<Map<String, dynamic>>> fetchBuildings() async {
    final data = await _client.from('classrooms').select();
    return data.map<Map<String, dynamic>>((c) {
      return {
        'id': c['id'],
        'building_name': c['name'] ?? c['room_number'] ?? c['classroom_name'] ?? 'وجهة غير معروفة',
        'latitude': c['latitude'] ?? c['lat'],
        'longitude': c['longitude'] ?? c['lng'],
      };
    }).toList();
  }

  /// Fetch classrooms belonging to a building.
  Future<List<Map<String, dynamic>>> fetchClassrooms(int buildingId) async {
    final data = await _client
        .from('classrooms')
        .select()
        .eq('building_id', buildingId);
    return List<Map<String, dynamic>>.from(data);
  }
}
