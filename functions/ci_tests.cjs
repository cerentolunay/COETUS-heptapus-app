'use strict';
const {spawnSync} = require('node:child_process');
const path = require('node:path');
for (const key of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  if (!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env[key] || '')) {
    console.error(`CI requires a local emulator: ${key}`);
    process.exit(1);
  }
}
const files = ['mutual_exchange_emulator.test.js', 'verification_emulator.test.js', 'verification_policy.test.js'];
const result = spawnSync(process.execPath, ['--test', '--test-concurrency=1', '--test-reporter=tap', ...files.map(f => path.join(__dirname, f))], {
  encoding: 'utf8', maxBuffer: 20 * 1024 * 1024,
});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
if (result.error) { console.error(result.error.message); process.exit(1); }
const summary = key => Number((result.stdout || '').match(new RegExp(`^# ${key} (\\d+)$`, 'm'))?.[1] ?? NaN);
const tests = summary('tests'), pass = summary('pass'), skipped = summary('skipped');
if (result.status !== 0 || !Number.isInteger(tests) || tests < 1 || pass !== tests || skipped !== 0) {
  console.error('CI requires all tests to pass with zero skips.');
  process.exit(1);
}
console.log(`CI verified: ${pass}/${tests} tests, 0 skips.`);
