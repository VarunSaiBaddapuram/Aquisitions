import logger from '#config/logger.js';
import { jwttoken } from '#utils/jwt.js';

// Attach decoded JWT payload (id, email, role) to req.user if a valid token exists.
// This middleware is non-strict: it never sends a response itself.
// Controllers or route-level guards decide whether authentication is required.
export const attachUserFromToken = (req, res, next) => {
  try {
    // 1) Prefer cookie (your auth.controller sets `token` cookie)
    let token = req.cookies?.token;

    // 2) Fallback to Authorization: Bearer <token>
    if (!token) {
      const authHeader = req.get('Authorization') || '';
      if (authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      }
    }

    if (!token) {
      // No token -> treat as unauthenticated; req.user remains undefined
      req.user = undefined;
      return next();
    }

    // 3) Verify and decode token
    const payload = jwttoken.verify(token); // throws on failure

    // 4) Attach to req.user
    req.user = {
      id: payload.id,
      email: payload.email,
      role: payload.role,
    };

    return next();
  } catch (e) {
    // Invalid/expired token -> log and treat as unauthenticated
    logger.warn('Invalid or expired JWT token', {
      error: e.message,
      ip: req.ip,
      path: req.path,
    });

    req.user = undefined;
    return next();
  }
};

// Optional strict guard: use on routes that must require authentication.
export const requireAuth = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication required',
    });
  }

  return next();
};
