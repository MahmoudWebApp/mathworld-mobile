import '../core/network/api_client.dart';
import '../widgets/geometry_diagram.dart';

/// Read-only geometry payload from MathWorld. Missing/invalid diagrams are absent.
class GeometryApiService {
  const GeometryApiService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>?> getDiagram(int problemId) async {
    if (problemId <= 0) return null;
    try {
      final response = await _api.get('/problems/$problemId/diagram');
      final envelope = response.data;
      if (envelope is! Map || envelope['Data'] is! Map) return null;
      final scene = Map<String, dynamic>.from(envelope['Data'] as Map);
      return isValidGeometryScene(scene) ? scene : null;
    } catch (_) {
      // A diagram is optional; network/404 failures must not block answering.
      return null;
    }
  }
}
