import { DatePipe, DecimalPipe } from '@angular/common';
import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { AdminApiService, CrmQueueItem } from '../../core/admin-api.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-crm-queue',
  imports: [DatePipe, DecimalPipe],
  templateUrl: './crm-queue.html',
  styleUrl: './crm-queue.scss'
})
export class CrmQueue implements OnInit {
  private readonly api = inject(AdminApiService);
  private readonly auth = inject(AuthService);
  protected readonly items = signal<CrmQueueItem[]>([]);
  protected readonly loading = signal(true);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly claimingId = signal<string | null>(null);
  protected readonly totalRequests = computed(() => this.items().reduce((sum, item) => sum + Number(item.request_count), 0));
  protected readonly unassigned = computed(() => this.items().filter((item) => !item.assigned_to).length);
  protected readonly currentUserId = computed(() => this.auth.identity()?.user.id ?? null);

  async ngOnInit(): Promise<void> { await this.reload(); }

  protected async reload(): Promise<void> {
    this.loading.set(true);
    this.errorMessage.set(null);
    try { this.items.set(await this.api.getCrmQueue()); }
    catch (error) { this.errorMessage.set(error instanceof Error ? error.message : 'Не удалось загрузить очередь.'); }
    finally { this.loading.set(false); }
  }

  protected async claim(item: CrmQueueItem): Promise<void> {
    this.claimingId.set(item.task_id);
    this.errorMessage.set(null);
    try {
      if (!(await this.api.claimTask(item.task_id))) throw new Error('Задачу уже забрал другой оператор. Обновите очередь.');
      await this.reload();
    } catch (error) {
      this.errorMessage.set(error instanceof Error ? error.message : 'Не удалось назначить задачу.');
    } finally { this.claimingId.set(null); }
  }
}
