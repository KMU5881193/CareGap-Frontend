import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {translateDemoLogin} from './demo-login-alias.mjs';
test('demo alias preserves the exact upstream identity and rejects wrong secrets / role selection',()=>{
 const rows=Array.from({length:4},(_,i)=>({identifier:`alias-${i}`,password:randomBytes(8).toString('hex'),upstream_identifier:`upstream-${i}`,upstream_password:randomBytes(24).toString('hex')}));
 for(const row of rows){assert.deepEqual(translateDemoLogin({identifier:row.identifier,password:row.password},rows),{identifier:row.upstream_identifier,password:row.upstream_password});assert.equal(translateDemoLogin({identifier:row.identifier,password:'wrong'},rows),null);assert.equal(translateDemoLogin({identifier:row.identifier,password:row.password,role:'admin'},rows),null);}
 assert.equal(translateDemoLogin({identifier:'unknown',password:'wrong'},rows),null);
 assert.throws(()=>translateDemoLogin({},[]));
});
