import { Component, inject, signal } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { runtimeConfig, runtimeIsConfigured } from '../../core/runtime-config';

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule],
  templateUrl: './login.html',
  styleUrl: './login.scss'
})
export class Login {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  protected readonly environment = runtimeConfig.environment;
  protected readonly configured = runtimeIsConfigured;
  protected readonly busy = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly form = new FormGroup({
    email: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.email] }),
    password: new FormControl('', { nonNullable: true, validators: [Validators.required] })
  });

  protected async submit(): Promise<void> {
    if (this.form.invalid || this.busy() || !this.configured) return;
    this.busy.set(true);
    this.errorMessage.set(null);
    try {
      const { email, password } = this.form.getRawValue();
      await this.auth.signIn(email, password);
      await this.router.navigateByUrl('/queue');
    } catch (error) {
      this.errorMessage.set(error instanceof Error ? error.message : 'Не удалось войти.');
    } finally {
      this.busy.set(false);
    }
  }
}
