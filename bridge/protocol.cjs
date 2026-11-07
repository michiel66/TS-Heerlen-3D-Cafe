'use strict';
const FRAME_BYTES = 960 * 2;
const MAX_MESSAGE = 12000;
const TYPES = new Set(['hello','connect','disconnect','ptt','pcm','roster']);
function decodeJSON(data) {
  if (Buffer.byteLength(data) > MAX_MESSAGE) throw Error('Bericht te groot');
  const msg = JSON.parse(data.toString());
  if (!msg || typeof msg !== 'object' || !TYPES.has(msg.type)) throw Error('Ongeldig bericht');
  return msg;
}
function nickname(value) {
  return String(value || 'Bezoeker').replace(/[\\/\x00-\x1f]/g,'').trim().slice(0,30) || 'Bezoeker';
}
function channel(value) {
  const text = String(value || '').trim();
  if (text.length > 120 || /[\x00-\x1f]/.test(text)) throw Error('Ongeldig kanaal');
  return text;
}
function fromClient(info) {
  return {id:String(info.id ?? info.clientId ?? info.clientID ?? ''),
    name:String(info.nickname ?? info.clientNickname ?? info.name ?? 'Onbekend').slice(0,60),
    channel:String(info.channelID ?? info.channelId ?? info.channel_id ?? ''),
    type:Number(info.type ?? info.clientType ?? 0)};
}
function pcmFromBase64(value) {
  if (typeof value !== 'string' || value.length > 3000 || !/^[A-Za-z0-9+/]*={0,2}$/.test(value)) throw Error('Ongeldige PCM');
  const buf=Buffer.from(value,'base64');
  if(buf.length!==FRAME_BYTES) throw Error('Verkeerde PCM frame-grootte');
  return buf;
}
module.exports = { FRAME_BYTES, decodeJSON, nickname, channel, fromClient, pcmFromBase64 };
