import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

/// Holds a Set<String> of perfume IDs currently in the user's wishlist.
/// Loaded at app start from GET /wishlist/ids for fast toggle checks.
final wishlistIdsProvider =
    StateNotifierProvider<WishlistIdsNotifier, Set<String>>((ref) {
  return WishlistIdsNotifier();
});

class WishlistIdsNotifier extends StateNotifier<Set<String>> {
  final ApiClient _api = ApiClient();

  WishlistIdsNotifier() : super({}) {
    load();
  }

  Future<void> load() async {
    try {
      final response = await _api.dio.get('/wishlist/ids');
      final ids = (response.data as List).map((e) => e.toString()).toSet();
      state = ids;
    } catch (_) {
      // Keep current state on error
    }
  }

  Future<bool> add(String perfumeId) async {
    // Optimistic update
    state = {...state, perfumeId};
    try {
      await _api.dio.post('/wishlist', data: {'perfume_id': perfumeId});
      return true;
    } catch (_) {
      // Revert
      state = Set.from(state)..remove(perfumeId);
      return false;
    }
  }

  Future<bool> remove(String perfumeId) async {
    // Optimistic update
    final previous = Set<String>.from(state);
    state = Set.from(state)..remove(perfumeId);
    try {
      await _api.dio.delete('/wishlist/$perfumeId');
      return true;
    } catch (_) {
      // Revert
      state = previous;
      return false;
    }
  }
}
