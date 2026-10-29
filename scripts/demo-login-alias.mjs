import {timingSafeEqual} from 'node:crypto';
// Trusted, gitignored local configuration only; never bundled into Flutter.
export function translateDemoLogin(input, rows) {
  if(!Array.isArray(rows)||rows.length!==4||new Set(rows.map(r=>r.identifier)).size!==4)throw Error('INVALID_DEMO_CONFIG');
  if(!input||Object.keys(input).sort().join(',')!=='identifier,password'||typeof input.identifier!=='string'||typeof input.password!=='string')return null;
  const row=rows.find(r=>r.identifier===input.identifier);
  if(!row||typeof row.password!=='string'||typeof row.upstream_identifier!=='string'||typeof row.upstream_password!=='string')return null;
  const actual=Buffer.from(input.password),expected=Buffer.from(row.password);
  if(actual.length!==expected.length||!timingSafeEqual(actual,expected))return null;
  return {identifier:row.upstream_identifier,password:row.upstream_password};
}
