import { Router } from 'express';
import {
  login,
  logout,
  me,
  refresh,
  register,
  registerDeviceInstallation,
  unregisterDeviceInstallation,
} from './auth.controller.ts';
import {
  deviceInstallationSchema,
  loginSchema,
  refreshSchema,
  registerSchema,
} from './auth.schemas.ts';
import { validateBody } from '../../shared/validate.ts';
import { authenticate } from '../../shared/authenticate.ts';
import { requireActiveUser } from '../../shared/require-active-user.ts';

const router = Router();

router.post('/register', validateBody(registerSchema), register);
router.post('/login', validateBody(loginSchema), login);
router.post('/refresh', validateBody(refreshSchema), refresh);
router.post('/logout', validateBody(refreshSchema), logout);
router.get('/me', authenticate, me);
router.put(
  '/device-installation',
  authenticate,
  requireActiveUser,
  validateBody(deviceInstallationSchema),
  registerDeviceInstallation,
);
router.delete(
  '/device-installation',
  authenticate,
  requireActiveUser,
  validateBody(deviceInstallationSchema),
  unregisterDeviceInstallation,
);

export default router;
