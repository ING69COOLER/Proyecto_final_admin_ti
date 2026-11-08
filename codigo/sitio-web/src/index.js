// Portal institucional EPA E.S.P.
// App Node.js/Express — sirve el sitio y expone endpoints de estado.
// Despliegue: Dokploy (producción, SSL) o Podman (intranet/dev).
const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Conexión opcional a PostgreSQL (la app funciona aunque no haya BD).
let pool = null;
if (process.env.DATABASE_URL) {
  const { Pool } = require('pg');
  pool = new Pool({ connectionString: process.env.DATABASE_URL });
}

// Sitio estático (public/index.html)
app.use(express.static(path.join(__dirname, '..', 'public')));

app.get('/health', (req, res) => {
  res.status(200).json({ estado: 'saludable', uptime: process.uptime(), plataforma: 'EPA' });
});

app.get('/info', (req, res) => {
  res.json({
    empresa: 'Empresas Públicas de Armenia E.S.P.',
    node_version: process.version,
    platform: process.platform,
    arch: process.arch,
    memoria_mb: {
      total: Math.round(require('os').totalmem() / 1024 / 1024),
      libre: Math.round(require('os').freemem() / 1024 / 1024)
    }
  });
});

// Verifica la conexión a la base de datos
app.get('/api/estado-bd', async (req, res) => {
  if (!pool) return res.status(503).json({ bd: 'no configurada (defina DATABASE_URL)' });
  try {
    const r = await pool.query('SELECT now() AS hora');
    res.json({ bd: 'conectada', hora: r.rows[0].hora });
  } catch (e) {
    res.status(500).json({ bd: 'error', detalle: e.message });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Portal EPA corriendo en el puerto ${port}`);
});
