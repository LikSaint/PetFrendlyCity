import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

export const adminGuard: CanActivateFn = async () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  try {
    return (await auth.ensureAdmin()) || router.createUrlTree(['/login']);
  } catch {
    await auth.signOut();
    return router.createUrlTree(['/login']);
  }
};
