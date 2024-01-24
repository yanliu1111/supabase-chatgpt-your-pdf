select vault.create_secret(
  'http://api.supabase.internal:8000',
  'supabase_url'
);
-- vault in supasbase is a way to actually store configuration and secrets within the database itself. The reason why you might want to use Vault versus some other arbitrary table is because Vault actually encrypts your information. It is convenient kind of configuration tool you can use for both configuration and actual secrets. 