import { inject, Injectable, signal } from '@angular/core';
import { Session, User } from '@supabase/supabase-js';
import { SUPABASE } from './supabase-client';

export type AdminRole = 'ADMIN' | 'CALLER' | 'EDITOR' | 'EVENT_MANAGER';

export interface AdminIdentity {
  readonly user: User;
  readonly role: AdminRole;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly supabase = inject(SUPABASE);
  readonly session = signal<Session | null>(null);
  readonly identity = signal<AdminIdentity | null>(null);

  async initialize(): Promise<void> {
    const { data } = await this.supabase.auth.getSession();
    this.session.set(data.session);
    this.supabase.auth.onAuthStateChange((_event, session) => {
      this.session.set(session);
      if (!session) this.identity.set(null);
    });
  }

  async signIn(email: string, password: string): Promise<AdminIdentity> {
    const { data, error } = await this.supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    this.session.set(data.session);
    const identity = await this.loadIdentity(data.user);
    if (!identity) {
      await this.signOut();
      throw new Error('Для этого аккаунта не назначена активная Admin/CRM роль.');
    }
    return identity;
  }

  async ensureAdmin(): Promise<boolean> {
    const currentSession = this.session() ?? (await this.supabase.auth.getSession()).data.session;
    if (!currentSession) return false;
    this.session.set(currentSession);
    if (this.identity()) return true;
    return Boolean(await this.loadIdentity(currentSession.user));
  }

  async signOut(): Promise<void> {
    await this.supabase.auth.signOut();
    this.session.set(null);
    this.identity.set(null);
  }

  private async loadIdentity(user: User): Promise<AdminIdentity | null> {
    const { data, error } = await this.supabase
      .from('admin_users')
      .select('role')
      .eq('user_id', user.id)
      .eq('active', true)
      .maybeSingle();
    if (error) throw error;
    if (!data) return null;
    const identity = { user, role: data.role as AdminRole } satisfies AdminIdentity;
    this.identity.set(identity);
    return identity;
  }
}
