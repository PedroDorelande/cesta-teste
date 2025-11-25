# Repository Guidelines

## Project Structure & Module Organization
The workspace splits into `frontend/` (Next.js 15) and `backend/` (Express + TypeORM). Keep routes in `frontend/app`, primitives in `components/ui`, and cross-cutting code in `contexts`, `hooks`, `lib`, and `types`. Mirror the existing `backend/src` folders (`config`, `entities`, `controllers`, `services`, `routes`, `jobs`, `scripts`) when adding logic so dependencies remain predictable. Store datasets or SQL helpers inside `backend/data`, `backend/SINAPI`, or the root CSV files.

## Build, Test, and Development Commands
```bash
cd backend && npm run dev             # API on http://localhost:3001
cd backend && npm run build && npm start
cd backend && npm run migration:run   # apply TypeORM migrations
cd frontend && npm run dev            # Next.js on http://localhost:3000
cd frontend && npm run lint && npm run build
./run-backend.sh & ./run-frontend.sh  # convenience wrappers
```
Importer scripts such as `npm run import:bps -- ~/Downloads/bps.csv` rely on PostgreSQL env vars in `backend/.env` and stream logs to `backend/server.log`.

## Coding Style & Naming Conventions
Use strict TypeScript plus the `@/` alias (frontend resolves from repo root, backend from `src`), two-space indentation, and single quotes. React components, layouts, contexts, and hooks stay PascalCase; services, DTOs, and migrations use descriptive camelCase or kebab-case. Keep Tailwind utilities ordered (layout → spacing → color). Run `npm run lint` for the frontend and `npm run build` for the backend before committing.

## Testing Guidelines
A formal Jest/Vitest suite is still pending, so lean on linting, TypeScript, and the harnesses under `backend/test-*.ts` / `.sh` (run with `npx ts-node <file>`). Reproduce the affected UI/API flow end-to-end (auth invitations, PNCP sync, checklist edits) before submitting. New automated tests should live beside the feature with a `*.spec.ts[x]` suffix and cover success plus failure paths.

## Commit & Pull Request Guidelines
History follows Conventional Commits (`feat:`, `fix:`). Keep commits focused, note whether they touch `frontend`, `backend`, or migrations, and mention script/env adjustments in the body. Pull requests must summarize the change, link the related issue or checklist item, attach screenshots or terminal output for UI/API updates, and list manual steps executed; request review from a maintainer of the affected area.

## Security & Configuration Tips
Copy `.env.example` files for each package and keep populated `.env` files out of Git. PostgreSQL, SMTP, Zammad, and invite tokens belong in your runtime environment or the helper shell scripts. Scrub supplier data before checking CSVs into `backend/data`, and redact sensitive details in screenshots or logs shared in PRs.
