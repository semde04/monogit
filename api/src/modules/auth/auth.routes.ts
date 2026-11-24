import { Router } from 'express';
import { login, logout, refresh, register } from './auth.controller.ts';
import { loginSchema, refreshSchema, registerSchema } from './auth.schemas.ts';
import { validateBody } from '../../shared/validate.ts';

const router = Router();

router.post('/register', validateBody(registerSchema), register);
router.post('/login', validateBody(loginSchema), login);
router.post('/refresh', validateBody(refreshSchema), refresh);
router.post('/logout', validateBody(refreshSchema), logout);

export default router;
