// Renderiza una guia de alumno (HTML) a PDF usando Chrome headless por CDP.
//
// Por que no wkhtmltopdf: el proyecto esta archivado desde 2023 y ya no
// existe formula ni cask en Homebrew. Chrome headless produce el mismo
// resultado y soporta el pie de pagina con numeracion via footerTemplate.
//
//   node render-pdf.mjs <entrada.html> <salida.pdf> "<texto del pie izquierdo>"

import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [htmlIn, pdfOut, footerLeft] = process.argv.slice(2);
if (!htmlIn || !pdfOut || !footerLeft) {
  console.error('uso: node render-pdf.mjs <entrada.html> <salida.pdf> "<pie izquierdo>"');
  process.exit(2);
}

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9222 + Math.floor(process.pid % 500);
const profile = mkdtempSync(join(tmpdir(), 'chrome-pdf-'));

const MM = 1 / 25.4; // milimetros a pulgadas
const MARGIN = { top: 16 * MM, bottom: 18 * MM, left: 15 * MM, right: 15 * MM };

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// Pie: izquierda el titulo corto, derecha el numero de pagina. 7pt Helvetica,
// los mismos valores que pedia la linea de wkhtmltopdf del encargo.
const footerTemplate = `
<div style="font-family:Helvetica,Arial,sans-serif;font-size:7pt;color:#7a8f88;
            width:100%;margin:0 15mm;display:flex;justify-content:space-between;">
  <span>${esc(footerLeft)}</span><span class="pageNumber"></span>
</div>`;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const chrome = spawn(CHROME, [
  '--headless=new',
  `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${profile}`,
  '--no-first-run', '--no-default-browser-check', '--disable-gpu',
  '--allow-file-access-from-files', '--hide-scrollbars', '--force-color-profile=srgb',
  'about:blank',
], { stdio: 'ignore' });

let ws;
const cleanup = () => {
  try { ws?.close(); } catch {}
  try { chrome.kill('SIGKILL'); } catch {}
  try { rmSync(profile, { recursive: true, force: true }); } catch {}
};

try {
  // 1 · esperar a que el endpoint de DevTools conteste
  let version = null;
  for (let i = 0; i < 100 && !version; i++) {
    try { version = await (await fetch(`http://127.0.0.1:${PORT}/json/version`)).json(); }
    catch { await sleep(100); }
  }
  if (!version) throw new Error('Chrome no levanto el puerto de depuracion');

  // 2 · conectar al navegador y abrir una pestana propia
  ws = new WebSocket(version.webSocketDebuggerUrl);
  await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = ko; });

  let id = 0;
  const pending = new Map();
  const events = [];
  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id !== undefined) {
      const p = pending.get(msg.id); pending.delete(msg.id);
      msg.error ? p.ko(new Error(JSON.stringify(msg.error))) : p.ok(msg.result);
    } else events.push(msg);
  };
  const send = (method, params = {}, sessionId) =>
    new Promise((ok, ko) => {
      const n = ++id;
      pending.set(n, { ok, ko });
      ws.send(JSON.stringify({ id: n, method, params, ...(sessionId ? { sessionId } : {}) }));
    });

  const url = pathToFileURL(resolve(htmlIn)).href;
  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });

  await send('Page.enable', {}, sessionId);
  await send('Page.navigate', { url }, sessionId);

  // 3 · esperar el load y darle un respiro al layout de las fuentes
  for (let i = 0; i < 300; i++) {
    if (events.some((e) => e.method === 'Page.loadEventFired')) break;
    await sleep(50);
  }
  await sleep(600);

  // 4 · imprimir
  const { data } = await send('Page.printToPDF', {
    printBackground: true,
    paperWidth: 8.27, paperHeight: 11.69,       // A4
    marginTop: MARGIN.top, marginBottom: MARGIN.bottom,
    marginLeft: MARGIN.left, marginRight: MARGIN.right,
    displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate,
    preferCSSPageSize: false,
  }, sessionId);

  writeFileSync(pdfOut, Buffer.from(data, 'base64'));
  console.log(`OK  ${pdfOut}`);
} catch (e) {
  console.error('FALLO:', e.message);
  cleanup();
  process.exit(1);
}
cleanup();
process.exit(0);
