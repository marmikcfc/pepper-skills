#!/usr/bin/env node
import Orthogonal from '@orth/sdk';
import { appendFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

const args = process.argv.slice(2);

function usage(): void {
  process.stderr.write(
    'Usage:\n' +
    '  orth run <api> <path> [--query key=val ...] [--body json]\n' +
    '  orth balance\n' +
    '  orth usage [--limit N]\n' +
    '  orth search <query>\n'
  );
}

function getApiKey(): string {
  const key = process.env.ORTHOGONAL_API_KEY;
  if (!key) {
    process.stderr.write('Error: ORTHOGONAL_API_KEY environment variable not set\n');
    process.exit(1);
  }
  return key;
}

function logCost(entry: {
  api: string;
  path: string;
  price_usd: string;
  success: boolean;
}): void {
  const costFile = process.env.DATA_COSTS_FILE ||
    `${process.env.WORKSPACE_GROUP || '/workspace/group'}/.data-costs.jsonl`;
  const line = JSON.stringify({
    ts: new Date().toISOString(),
    provider: 'orthogonal',
    ...entry,
  });
  try {
    const dir = dirname(costFile);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
    appendFileSync(costFile, line + '\n');
  } catch {
    // Non-fatal: workspace may not exist in dev/test
  }
}

async function cmdRun(api: string, path: string, rawArgs: string[]): Promise<void> {
  const query: Record<string, string> = {};
  let body: Record<string, unknown> | undefined;

  for (let i = 0; i < rawArgs.length; i++) {
    const flag = rawArgs[i];
    if (flag === '--query' || flag === '-q') {
      const kv = rawArgs[++i];
      if (!kv) { process.stderr.write('Error: --query requires key=value\n'); process.exit(1); }
      const eq = kv.indexOf('=');
      if (eq < 1) { process.stderr.write(`Error: invalid --query format: ${kv}\n`); process.exit(1); }
      query[kv.slice(0, eq)] = kv.slice(eq + 1);
    } else if (flag === '--body' || flag === '-d') {
      const raw = rawArgs[++i];
      if (!raw) { process.stderr.write('Error: --body requires JSON string\n'); process.exit(1); }
      try { body = JSON.parse(raw); }
      catch { process.stderr.write('Error: --body value is not valid JSON\n'); process.exit(1); }
    }
  }

  const orthogonal = new Orthogonal({ apiKey: getApiKey() });

  const response = await orthogonal.run({
    api,
    path,
    query: Object.keys(query).length > 0 ? query : undefined,
    body,
  });

  logCost({ api, path, price_usd: response.price, success: response.success });
  process.stderr.write(`✓ ${api} ${path} — $${response.price}\n`);
  process.stdout.write(JSON.stringify(response.data, null, 2) + '\n');
}

async function cmdBalance(): Promise<void> {
  const res = await fetch('https://api.orth.sh/v1/credits/balance', {
    headers: { Authorization: `Bearer ${getApiKey()}` },
  });
  const data = await res.json() as { balance?: string };
  process.stdout.write(`Balance: ${data.balance ?? 'unknown'}\n`);
}

async function cmdUsage(rawArgs: string[]): Promise<void> {
  const limitIdx = rawArgs.indexOf('--limit');
  const limit = limitIdx >= 0 ? rawArgs[limitIdx + 1] : '20';
  const res = await fetch(`https://api.orth.sh/v1/credits/usage?limit=${limit}`, {
    headers: { Authorization: `Bearer ${getApiKey()}` },
  });
  const data = await res.json();
  process.stdout.write(JSON.stringify(data, null, 2) + '\n');
}

async function cmdSearch(query: string): Promise<void> {
  const res = await fetch('https://api.orth.sh/v1/search', {
    method: 'POST',
    headers: { Authorization: `Bearer ${getApiKey()}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt: query, limit: 10 }),
  });
  const data = await res.json() as { results?: Array<{ name: string; slug: string; endpoints?: Array<{ path: string; description?: string }> }> };
  if (!data.results) { process.stdout.write(JSON.stringify(data, null, 2) + '\n'); return; }
  for (const r of data.results) {
    process.stdout.write(`${r.name} (${r.slug})\n`);
    for (const ep of r.endpoints ?? []) {
      process.stdout.write(`  ${ep.path}${ep.description ? ' — ' + ep.description : ''}\n`);
    }
  }
}

const cmd = args[0];

try {
  if (cmd === 'run') {
    if (!args[1] || !args[2]) { usage(); process.exit(1); }
    await cmdRun(args[1], args[2], args.slice(3));
  } else if (cmd === 'balance') {
    await cmdBalance();
  } else if (cmd === 'usage') {
    await cmdUsage(args.slice(1));
  } else if (cmd === 'search') {
    if (!args[1]) { usage(); process.exit(1); }
    await cmdSearch(args.slice(1).join(' '));
  } else {
    usage();
    process.exit(1);
  }
} catch (err) {
  process.stderr.write(`Error: ${err instanceof Error ? err.message : String(err)}\n`);
  process.exit(1);
}
