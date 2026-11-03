import 'package:flutter_riverpod/flutter_riverpod.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const showDrafts = bool.fromEnvironment('SHOW_DRAFTS');

bool get hasBackend => supabaseUrl.isNotEmpty;

/// Injectable so tests can simulate builds with and without a backend.
final hasBackendProvider = Provider<bool>((ref) => hasBackend);
