import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatusCount {
  const StatusCount(this.table, this.status, this.n);
  final String table;
  final KnowledgeStatus status;
  final int n;
}

/// Tables the admin can publish, in display order (matches the server whitelist).
const adminTables = [
  'governorates',
  'wilayats',
  'crops',
  'crop_requirements',
  'crop_stages',
  'crop_kc_monthly',
];

abstract class AdminRepository {
  Future<bool> signIn(String email, String password);
  Future<bool> isAdmin();
  Future<void> signOut();
  Future<List<StatusCount>> counts();
  Future<int> publishReviewed(String table);
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<bool> signIn(String email, String password) async {
    final res =
        await _c.auth.signInWithPassword(email: email, password: password);
    return res.session != null;
  }

  @override
  Future<bool> isAdmin() async => (await _c.rpc('is_admin')) == true;

  @override
  Future<void> signOut() => _c.auth.signOut();

  @override
  Future<List<StatusCount>> counts() async {
    final rows = await _c.rpc('knowledge_status_counts') as List;
    return [
      for (final r in rows)
        StatusCount(
          r['table_name'] as String,
          KnowledgeStatus.parse(r['status']),
          (r['n'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<int> publishReviewed(String table) async =>
      ((await _c.rpc('publish_reviewed', params: {'p_table': table})) as num)
          .toInt();
}

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => SupabaseAdminRepository());
