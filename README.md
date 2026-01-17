# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Key Commands

### Install dependencies

- `npm install`

### Run the API locally

- Start the development server (Node watch mode, reloads on changes):
  - `npm run dev`
- By default, the server listens on `http://localhost:${PORT}` where `PORT` comes from the environment (falls back to `3000`).

### Linting and formatting
### made for another push action

- Run ESLint on the whole project:
  - `npm run lint`
- Run ESLint and automatically fix simple issues:
  - `npm run lint:fix`
- Format the codebase with Prettier:
  - `npm run format`
- Check formatting without writing changes:
  - `npm run format:check`

### Database (Drizzle + Neon/Postgres)

Drizzle is configured via `drizzle.config.js` and models in `src/models/*.js`. The database connection uses `process.env.DATABASE_URL`.

- Generate Drizzle SQL from the schema:
  - `npm run db:generate`
- Apply migrations:
  - `npm run db:migrate`
- Open the Drizzle studio UI:
  - `npm run db:studio`

### Tests

There is currently no test runner or `npm test` script configured, although ESLint includes a `tests/**/*.js` override. Before assuming how to run a single test, confirm with the user which test framework (if any) has been added.

## High-Level Architecture

### Entry point and server

- `src/index.js`
  - Loads environment variables via `dotenv/config`.
  - Imports `src/server.js` (side-effect) to start the HTTP server.
- `src/server.js`
  - Imports the Express app from `src/app.js`.
  - Reads `process.env.PORT || 3000` and calls `app.listen(PORT, ...)`.

### Express application and routes

- `src/app.js`
  - Constructs the Express app and applies common middleware:
    - `helmet` for basic security headers.
    - `cors` with default configuration.
    - JSON and URL-encoded body parsers.
    - `cookie-parser` to work with signed/secure cookies.
    - `morgan` HTTP logger wired into the Winston logger from `#config/logger.js`.
    - `securityMiddleware` from `#middleware/security.middleware.js` for Arcjet-based protection and rate limiting.
  - Defines basic health and info endpoints:
    - `GET /` – simple text response plus a log message.
    - `GET /health` – returns `{ status, timestamp, uptime }` for liveness checks.
    - `GET /api` – simple JSON status message.
  - Mounts authentication routes under `/api/auth` using `authRoutes` from `src/routes/auth.routes.js`.

### Routing and controllers

- `src/routes/auth.routes.js`
  - Declares the auth API surface:
    - `POST /api/auth/sign-up` → `signup` controller.
    - `POST /api/auth/sign-in` → `signIn` controller.
    - `POST /api/auth/sign-out` → `signOut` controller.
- `src/controllers/auth.controller.js`
  - Orchestrates HTTP-layer logic for auth, delegating persistence and crypto to services and utilities.
  - `signup(req, res, next)`:
    - Validates `req.body` with `signupSchema` from `#validations/auth.validation.js`.
    - Calls `createUser` from `#services/auth.service.js`.
    - Issues a JWT via `jwttoken.sign` and stores it using `cookies.set` from `#utils/cookies.js`.
    - Returns a sanitized user payload (no password) and logs success.
  - `signIn(req, res, next)`:
    - Requires `email` and `password` in the body.
    - Uses `authenticateUser` from `#services/auth.service.js` to verify credentials.
    - Issues a JWT and cookie, then returns user info.
  - `signOut(req, res, next)`:
    - Clears the `token` cookie via `cookies.clear` and returns a success message.

### Services and data layer

- `src/services/auth.service.js`
  - Implements business logic for user creation and authentication.
  - Uses `bcrypt` to hash and compare passwords.
  - Uses Drizzle (`db` from `#config/database.js`) and the `users` table from `#models/user.model.js`.
  - `createUser`:
    - Checks for an existing user by email.
    - Hashes the password and inserts a new row, returning selected fields.
  - `authenticateUser`:
    - Fetches a user by email and validates the provided password.
- `src/models/user.model.js`
  - Defines the `users` table with Drizzle `pgTable`:
    - `id`, `name`, `email` (unique), `password`, `role`, `created_at`, `updated_at`.
- `src/config/database.js`
  - Creates a Neon SQL client from `@neondatabase/serverless` using `process.env.DATABASE_URL`.
  - Wraps it with Drizzle (`drizzle-orm/neon-http`) and exports `{ db, sql }`.
- `drizzle.config.js`
  - Points Drizzle at `./src/models/*.js` for schema and `./drizzle` as the migrations output directory.

### Security, rate limiting, and Arcjet

- `src/config/arcjet.js`
  - Configures the Arcjet client with `process.env.ARCJET_KEY` and a set of rules:
    - `shield` to protect against common attacks (e.g., SQL injection).
    - `detectBot` to block most bots while allowing selected categories.
    - A `slidingWindow` rule for baseline rate limiting.
- `src/middleware/security.middleware.js`
  - Applies per-request security checks using Arcjet.
  - Derives a `role` (default `'guest'`) and adjusts limits:
    - Admin: 20/min.
    - User: 10/min.
    - Guest: 5/min.
  - Invokes `aj.withRule(slidingWindow(...)).protect(req)` and inspects the decision:
    - Blocks and logs bot traffic, shield violations, and rate-limit violations with appropriate HTTP 403 responses.

### Logging

- `src/config/logger.js`
  - Defines a Winston logger with:
    - JSON logs including timestamps and error stacks.
    - File transports for `logs/error.log` and `logs/combined.log`.
  - In non-production (`NODE_ENV !== 'production'`), adds a colored console transport with a simple format.
  - Used across controllers and services for structured logging.

### Utilities and validation

- `src/utils/cookies.js`
  - Centralizes cookie options (e.g., `httpOnly`, `sameSite`, `secure` in production, 15-minute `maxAge`).
  - Exposes helpers `set`, `clear`, and `get` to keep cookie handling consistent.
- `src/utils/jwt.js`
  - Wraps `jsonwebtoken` with a small API (`jwttoken.sign` / `jwttoken.verify`).
  - Reads `JWT_SECRET` from the environment (with a development default) and uses a 1-day expiration.
- `src/utils/format.js`
  - Provides `formatValidationError` to turn Zod error objects into human-readable strings.
- `src/validations/auth.validation.js`
  - Declares Zod schemas for auth payloads (currently signup + signin) and is used by the auth controller.

### Module resolution

- `package.json` defines `imports` aliases for cleaner imports:
  - `#config/*` → `./src/config/*`
  - `#controllers/*` → `./src/controllers/*`
  - `#middleware/*` → `./src/middleware/*`
  - `#models/*` → `./src/models/*`
  - `#routes/*` → `./src/routes/*`
  - `#services/*` → `./src/services/*`
  - `#utils/*` → `./src/utils/*`
  - `#validations/*` → `./src/validations/*`

When navigating or editing code, prefer these aliases to relative paths to stay consistent with the existing structure.
