import { inject, Injectable } from '@angular/core';
import { SUPABASE } from './supabase-client';

export type CrmTaskStatus = 'OPEN' | 'IN_PROGRESS' | 'WAITING_CALLBACK';
export type CrmTaskType = 'VERIFY_POLICY' | 'REVERIFY_POLICY' | 'FOLLOW_UP' | 'RESOLVE_REPORT';

export interface CrmQueueItem {
  readonly task_id: string;
  readonly place_id: string;
  readonly google_place_id: string | null;
  readonly task_type: CrmTaskType;
  readonly task_status: CrmTaskStatus;
  readonly priority_score: number;
  readonly assigned_to: string | null;
  readonly unique_requesters: number;
  readonly request_count: number;
  readonly place_open_count: number;
  readonly navigation_count: number;
  readonly created_at: string;
}

@Injectable({ providedIn: 'root' })
export class AdminApiService {
  private readonly supabase = inject(SUPABASE);

  async getCrmQueue(): Promise<CrmQueueItem[]> {
    const { data, error } = await this.supabase.rpc('admin_crm_queue');
    if (error) throw error;
    return (data ?? []) as CrmQueueItem[];
  }

  async claimTask(taskId: string): Promise<boolean> {
    const { data, error } = await this.supabase.rpc('admin_claim_crm_task', {
      claimed_task_id: taskId
    });
    if (error) throw error;
    return data === true;
  }
}
