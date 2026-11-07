'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const p = require('../protocol.cjs');
test('PCM is exact 20 ms, 48 kHz mono',()=>{assert.equal(p.pcmFromBase64(Buffer.alloc(1920).toString('base64')).length,1920);});
test('verkeerde audio wordt afgewezen',()=>{assert.throws(()=>p.pcmFromBase64('AQID'),/grootte/);});
test('berichtlimiet en typevalidatie',()=>{assert.equal(p.decodeJSON(Buffer.from('{"type":"ptt","active":true}')).type,'ptt');assert.throws(()=>p.decodeJSON(Buffer.from('{"type":"execute"}')));});
test('gebruikersnaam wordt beperkt',()=>{assert.equal(p.nickname('   Papa  '),'Papa');assert.equal(p.nickname('X'.repeat(50)).length,30);});
test('TS3-gebruikerconversie',()=>{assert.deepEqual(p.fromClient({id:12,nickname:'Jan',channelID:23n}),{id:'12',name:'Jan',channel:'23',type:0});});
