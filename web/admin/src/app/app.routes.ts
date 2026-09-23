import { Routes } from '@angular/router';
import { adminGuard } from './core/admin.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/login/login').then((module) => module.Login)
  },
  {
    path: '',
    canActivate: [adminGuard],
    loadComponent: () =>
      import('./layout/admin-shell/admin-shell').then((module) => module.AdminShell),
    children: [
      {
        path: 'queue',
        loadComponent: () =>
          import('./features/crm-queue/crm-queue').then((module) => module.CrmQueue)
      },
      { path: '', pathMatch: 'full', redirectTo: 'queue' }
    ]
  },
  { path: '**', redirectTo: '' }
];
