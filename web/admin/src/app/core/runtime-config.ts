export interface RuntimeConfig {
  readonly supabaseUrl: string;
  readonly supabaseAnonKey: string;
  readonly environment: string;
}

declare global {
  interface Window {
    __PET_FRIENDLY_CONFIG__?: Partial<RuntimeConfig>;
  }
}

const source = window.__PET_FRIENDLY_CONFIG__ ?? {};

export const runtimeConfig: RuntimeConfig = {
  supabaseUrl: source.supabaseUrl || 'http://127.0.0.1:54321',
  supabaseAnonKey: source.supabaseAnonKey || 'not-configured',
  environment: source.environment || 'local'
};

export const runtimeIsConfigured = Boolean(source.supabaseUrl) && Boolean(source.supabaseAnonKey);
