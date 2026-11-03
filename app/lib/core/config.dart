const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const showDrafts = bool.fromEnvironment('SHOW_DRAFTS');

bool get hasBackend => supabaseUrl.isNotEmpty;
