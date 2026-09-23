import { InjectionToken, Provider } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { runtimeConfig } from './runtime-config';

export const SUPABASE = new InjectionToken<SupabaseClient>('SUPABASE');

export function provideSupabase(): Provider {
  return {
    provide: SUPABASE,
    useFactory: () =>
      createClient(runtimeConfig.supabaseUrl, runtimeConfig.supabaseAnonKey, {
        auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true }
      })
  };
}
