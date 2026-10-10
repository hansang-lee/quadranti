// Drives a headless Chrome over the DevTools protocol to click through the
// web build and take screenshots. See docs/development.md, "Looking at the UI".
//
// Usage: SHOTS=<dir> bun tool/web_driver.ts <step> [<step> ...]
// Steps: goto:<url> | click:<x>,<y> | drag:<x1>,<y1>,<x2>,<y2> | type:<text>
//        key:<Enter|Tab> | wait:<ms> | shot:<name>   (saves <SHOTS>/<name>.png)
//        scheme:<light|dark>   (prefers-color-scheme; put it before goto)
//        downloads:<dir>       (let the page download into <dir>; lasts for this run only,
//                               so put it in the same invocation as the click)
// Expects Chrome listening on localhost:9333 (--remote-debugging-port=9333).
// The viewport is fixed at 412x860, a typical phone.
const SHOTS = process.env.SHOTS ?? '.';
const targets = await (await fetch('http://localhost:9333/json')).json();
let page = targets.find((t: any) => t.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(r => ws.onopen = r);
let id = 0; const pending = new Map();
ws.onmessage = (m) => { const d = JSON.parse(m.data as string); if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id); } };
const send = (method: string, params: any = {}) => new Promise<any>(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send('Emulation.setDeviceMetricsOverride', { width: 412, height: 860, deviceScaleFactor: 1, mobile: false });
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms));
const mouse = async (type: string, x: number, y: number) => send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1, pointerType: 'mouse' });
for (const step of process.argv.slice(2)) {
  const [cmd, ...rest] = step.split(':'); const arg = rest.join(':');
  if (cmd === 'goto') { await send('Page.navigate', { url: arg }); await sleep(4000); }
  else if (cmd === 'click') { const [x, y] = arg.split(',').map(Number); await mouse('mouseMoved', x, y); await mouse('mousePressed', x, y); await sleep(60); await mouse('mouseReleased', x, y); await sleep(700); }
  else if (cmd === 'drag') { const [x1, y1, x2, y2] = arg.split(',').map(Number); await mouse('mousePressed', x1, y1); for (let i = 1; i <= 10; i++) { await mouse('mouseMoved', x1 + (x2 - x1) * i / 10, y1 + (y2 - y1) * i / 10); await sleep(30); } await mouse('mouseReleased', x2, y2); await sleep(700); }
  else if (cmd === 'type') { await send('Input.insertText', { text: arg }); await sleep(300); }
  else if (cmd === 'key') { const code = arg; const vk: any = { Enter: 13, Tab: 9 }; await send('Input.dispatchKeyEvent', { type: 'keyDown', key: code, code, windowsVirtualKeyCode: vk[code] }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: code, code, windowsVirtualKeyCode: vk[code] }); await sleep(500); }
  else if (cmd === 'downloads') { await send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: arg }); }
  else if (cmd === 'scheme') { await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: arg }] }); }
  else if (cmd === 'wait') { await sleep(Number(arg)); }
  else if (cmd === 'shot') { const r = await send('Page.captureScreenshot', { format: 'png' }); await Bun.write(`${SHOTS}/${arg}.png`, Buffer.from(r.result.data, 'base64')); }
}
ws.close();
