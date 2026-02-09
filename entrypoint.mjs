/**
 * Distroless entrypoint – no shell available.
 * 1. Runs prisma migrate deploy via child_process (no npx/sh needed).
 * 2. Starts the Fastify server.
 */
import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';

// ── Migrations ──────────────────────────────────────────────
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const prismaCli = join(__dirname, 'node_modules', 'prisma', 'build', 'index.js');

if (!existsSync(prismaCli)) {
    console.error('❌ prisma CLI not found at', prismaCli);
    process.exit(1);
}

console.log('🚀 Running database migrations…');
try {
    execFileSync(process.execPath, [prismaCli, 'migrate', 'deploy'], {
        stdio: 'inherit',
        env: process.env,
    });
    console.log('✅ Migrations completed');
} catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
}

// ── Start server ────────────────────────────────────────────
console.log('🚀 Starting server…');
await import('./dist/index.js');
