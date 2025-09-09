const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

app.get('/', (_, res) => {
  res.set('Content-Type','text/html; charset=utf-8');
  res.send(`
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Emoji Ratings</title>
    <style>
      body { font-family: Segoe UI Emoji, Noto Color Emoji, Apple Color Emoji, Segoe UI, Arial, sans-serif; }
      button { font-size: 16px; margin-right: 8px; }
      pre { background:#f6f8fa; padding:10px; }
    </style>
  </head>
  <body>
    <h2>Emoji Ratings</h2>
    <button onclick=\"vote('👍')\">Vote &#128077;</button>
    <button onclick=\"vote('👎')\">Vote &#128078;</button>
    <div id=\"out\"></div>
    <script>
      async function load(){
        const r = await fetch('/api/results');
        const data = await r.json();
        const entries = Object.entries(data).sort();
        const html = entries.map(([k,v])=>`<div style="font-size:18px">${k} : <strong>${v}</strong></div>`).join('');
        document.getElementById('out').innerHTML = html || '<em>No votes yet</em>';
      }
      async function vote(item){
        await fetch('/api/vote', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({item})});
        await load();
      }
      load();
    </script>
  </body></html>
  `);
});
app.get('/health', (_, res) => res.send('OK'));
app.listen(PORT, () => console.log('frontend on', PORT));
