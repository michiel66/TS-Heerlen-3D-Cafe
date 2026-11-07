'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');

const bridgeSource = fs.readFileSync(path.join(__dirname, '..', 'main.cjs'), 'utf8');
const protocol = require('../protocol.cjs');

function createContext() {
  const messages = [];
  class FakeWSS { on() {} }
  const fakeRequire = (id) => {
    if (id === 'ws') return { WebSocketServer: FakeWSS, WebSocket: { OPEN: 1 } };
    if (id === './protocol.cjs') return protocol;
    if (id === 'node:fs') return { mkdirSync() {} };
    return require(id);
  };
  const ctx = vm.createContext({
    require: fakeRequire,
    process: { argv: ['node', 'main.cjs', 'a'.repeat(48), '/tmp/voice'] , env: {}, cwd: () => '/tmp', on() {} },
    Buffer, console: { log() {}, error() {} },
    setTimeout: () => 1, clearTimeout() {},
    setInterval: () => 1, clearInterval() {},
    AbortSignal, Date,
    capture: (str) => messages.push(JSON.parse(str)),
  });
  vm.runInContext(bridgeSource, ctx);
  vm.runInContext(`
    connected=true;
    authed=true;
    connectedNickname='Ikzelf';
    client={clientID:()=>1, channelID:()=>3n};
    socket={readyState:1,send:capture};
  `,ctx);
  return {ctx,messages};
}

test('gebruiker via server-events verschijnt zonder clientlist-rechten', async () => {
  const {ctx,messages} = createContext();
  vm.runInContext(`
    rememberClientEnter({id:1,nickname:'Ikzelf',channelID:3n,type:0});
    rememberClientEnter({id:7,nickname:'Gerrit',channelID:3n,type:0});
    sdk={listClients: async () => {throw new Error('insufficient permissions');}};
  `,ctx);
  await vm.runInContext('refreshRoster()',ctx);
  const last=messages.filter(m=>m.type==='roster').at(-1);
  assert.deepEqual(last.users.map(u=>u.name), ['Ikzelf','Gerrit']);
  assert.equal(last.ownClientId,'1');
  assert.equal(last.source,'server-events');
  vm.runInContext('rememberClientLeave({id:7});',ctx);
  const after=messages.filter(m=>m.type==='roster').at(-1);
  assert.deepEqual(after.users.map(u=>u.name),['Ikzelf']);
});
