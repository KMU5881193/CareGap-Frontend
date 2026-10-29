import { test as base, expect } from '@playwright/test';
import { createServer } from 'vite';
import type { AddressInfo } from 'node:net';

export const test = base.extend<{}, { appUrl: string }>({
  appUrl: [async ({}, use) => {
    const server = await createServer({ server: { host: '127.0.0.1', port: 0, strictPort: true } });
    try {
      await server.listen();
      const address = server.httpServer?.address();
      if (!address || typeof address === 'string') throw new Error('Vite did not allocate a test port');
      await use(`http://127.0.0.1:${(address as AddressInfo).port}`);
    } finally {
      await server.close();
    }
  }, { scope: 'worker' }],
  baseURL: async ({ appUrl }, use) => { await use(appUrl); },
});
export { expect };
