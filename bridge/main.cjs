'use strict';
// De websocket luistert alleen op localhost en accepteert uitsluitend een token dat
// het 3D programma bij het starten genereert. Geen losse server en geen TS-plugin.
const fs = require('node:fs');
const path = require('node:path');
const { WebSocketServer, WebSocket } = require('ws');
const { decodeJSON, nickname, channel, fromClient, pcmFromBase64 } = require('./protocol.cjs');
const PORT = 39453;
const args = process.argv.slice(2);
const token = args[0] || '';
const userDir = args[1] || path.join(process.env.APPDATA || process.cwd(), 'TS-Heerlen-Cafe');
if (!/^[0-9a-f]{48}$/.test(token)) {
  console.error('Bridge vereist een geheim 48-tekens token van de cafe-app.');
  process.exit(2);
}
fs.mkdirSync(userDir, { recursive: true });
let socket = null, authed = false, sdk = null, client = null, opusTx = null;
let connected = false, transmitting = false, busyConnect = false;
let listTimer = null, activeSpeaker = null, activeUntil = 0;
let decoders = new Map(), lastRoster = [];

function out(type, fields = {}) {
  if (authed && socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify({type,...fields}));
}
function status(message) { out('status',{connected,message}); }
function failure(err) { out('error',{message:String(err?.message || err).slice(0,240)}); }
function identityFile() { return path.join(userDir,'teamspeak-identity.txt'); }
function identity() {
  try {return sdk.identityFromString(fs.readFileSync(identityFile(),'utf8').trim());}
  catch (err) {
    if(err?.code && err.code !== 'ENOENT') throw err;
    const value = sdk.generateIdentity(8);
    fs.writeFileSync(identityFile(), value.toString(), {mode:0o600});
    return value;
  }
}
function myChannel() {
  try {return String(client?.channelID?.() ?? '');} catch {return '';}
}
async function refreshRoster() {
  if(!connected || !client || !sdk) return;
  try {
    const clients = typeof sdk.listClients === 'function' ? await sdk.listClients(client)
      : (typeof client.listClients === 'function' ? await client.listClients() : []);
    if(!Array.isArray(clients)) throw Error('Geen geldige clientlijst ontvangen');
    lastRoster = clients.map(fromClient).filter(u => u.type === 0 && u.id);
    out('roster', {users:lastRoster.slice(0,500), ownChannel:myChannel()});
  } catch(err) {out('error',{message:'Gebruikerslijst: '+String(err.message).slice(0,170)});}
}
function processVoice(packet) {
  if(!connected || !packet || ![4,5].includes(packet.codec) || !packet.data || !packet.data.length) return;
  const id = Number(packet.clientId ?? -1);
  if(!Number.isInteger(id) || id < 0) return;
  const now = Date.now();
  if(activeSpeaker !== id && activeUntil > now) return; // geen twee streams door elkaar
  activeSpeaker = id; activeUntil = now + 140;
  let decoder = decoders.get(id);
  try {
    if(!decoder) {
      const OpusScript = require('opusscript');
      decoder = new OpusScript(48000, packet.codec === 5 ? 2 : 1, OpusScript.Application.VOIP);
      decoders.set(id,decoder);
    }
    const decoded = decoder.decode(Buffer.isBuffer(packet.data) ? packet.data : Buffer.from(packet.data));
    const channels = packet.codec === 5 ? 2 : 1;
    let mono = decoded;
    if(channels === 2) {
      mono = Buffer.alloc(Math.floor(decoded.length / 4) * 2);
      for(let i=0;i<mono.length/2;i++) {
        mono.writeInt16LE(Math.round((decoded.readInt16LE(i*4)+decoded.readInt16LE(i*4+2))/2),i*2);
      }
    }
    if(mono.length && mono.length <= 5760) {
      out('audio',{clientId:id,pcm:mono.toString('base64')});
      out('talking',{clientId:id});
    }
  } catch(err) {out('error',{message:'Opus RX: '+String(err.message).slice(0,150)});}
}
async function connectTS(msg) {
  if(busyConnect || connected) return;
  busyConnect = true;
  status('Verbinden met Heerlen.MIJNTS3.NL…');
  try {
    sdk = await import('@honeybbq/teamspeak-client');
    const OpusScript = require('opusscript');
    opusTx = new OpusScript(48000,1,OpusScript.Application.VOIP);
    opusTx.setBitrate(24000);
    const nick = nickname(msg.nickname);
    const room = channel(msg.channel);
    client = new sdk.Client(identity(), 'Heerlen.MIJNTS3.NL', nick, {
      defaultChannel:room,
      logger:{debug(){},info(){},warn(){},error(){}}
    });
    client.on('voiceData',processVoice);
    client.on('clientEnter',()=>{void refreshRoster();});
    client.on('clientMoved',()=>{void refreshRoster();});
    client.on('clientLeave',()=>{void refreshRoster();});
    client.on('disconnected',(err)=>{
      connected=false;transmitting=false;
      status('TeamSpeak verbinding verbroken'+(err?.message ? ': '+err.message : ''));
      out('roster',{users:[],ownChannel:''});
    });
    await client.connect();
    await client.waitConnected(AbortSignal.timeout(18000));
    connected = true;
    status('Verbonden als '+nick+' · kanaal '+(room || 'standaard'));
    await refreshRoster();
    clearInterval(listTimer);
    listTimer = setInterval(()=>{void refreshRoster();},5000);
  } catch(err) {failure(err); await disconnectTS();}
  finally {busyConnect = false;}
}
async function disconnectTS() {
  connected = false;
  transmitting = false;
  clearInterval(listTimer);
  listTimer = null;
  try {await client?.disconnect?.();} catch {}
  client = null;
  try {opusTx?.delete?.();}catch {}
  opusTx=null;
  for(const decoder of decoders.values()){try{decoder.delete();}catch{}}
  decoders.clear();activeSpeaker=null;activeUntil=0;
  status('Niet verbonden');
  out('roster',{users:[],ownChannel:''});
}
function sendPCM(msg) {
  if(!connected || !transmitting || !opusTx || !client) return;
  try {
    const raw = pcmFromBase64(msg.pcm);
    const packet = opusTx.encode(raw,960);
    client.sendVoice(packet,4);
  } catch(err) {failure(err);}
}
const server = new WebSocketServer({host:'127.0.0.1',port:PORT,maxPayload:12000,clientTracking:true});
server.on('connection',(ws)=>{
  if(socket && socket.readyState === WebSocket.OPEN){ws.close(1008,'Bezet');return;}
  socket=ws;authed=false;
  const deadline=setTimeout(()=>{if(!authed)ws.close(1008,'Authenticatie vereist');},4000);
  ws.on('message',async(data)=>{
    try {
      const msg=decodeJSON(data);
      if(!authed){
        if(msg.type!=='hello'||msg.token!==token){ws.close(1008,'Ongeldig token');return;}
        authed=true;clearTimeout(deadline);status('Lokale spraakmodule gereed');return;
      }
      if(msg.type==='connect') await connectTS(msg);
      else if(msg.type==='disconnect') await disconnectTS();
      else if(msg.type==='ptt') {
        const next = Boolean(msg.active) && connected;
        if(transmitting && !next && client) {
          try { client.sendVoice(Buffer.alloc(0), 4); } catch {}
        }
        transmitting = next;
      }
      else if(msg.type==='pcm') sendPCM(msg);
      else if(msg.type==='roster') await refreshRoster();
    } catch(err){failure(err);}
  });
  ws.on('close',()=>{clearTimeout(deadline);authed=false;socket=null;void disconnectTS();});
});
server.on('error',e=>{console.error('Lokale bridge:',e.message);process.exit(1);});
process.on('SIGTERM',()=>{void disconnectTS().finally(()=>process.exit(0));});
process.on('SIGINT',()=>{void disconnectTS().finally(()=>process.exit(0));});
console.log('TeamSpeak Heerlen lokale bridge gestart (127.0.0.1, toegang afgeschermd)');
