const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
const port = process.env.PORT || 3000;

// Configuration de la base de données
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'dbadmin',
  password: process.env.DB_PASSWORD || 'ChangeMe123!',
  database: process.env.DB_NAME || 'appdb'
};

// Middleware
app.use(cors());
app.use(express.json());

// Connexion à la base de données
let pool;
const initDb = async () => {
  try {
    pool = mysql.createPool(dbConfig);
    console.log('Connexion à la base de données établie');
    
    // Vérifier si la table existe, sinon la créer
    await pool.query(`
      CREATE TABLE IF NOT EXISTS items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Insérer des données de test si la table est vide
    const [rows] = await pool.query('SELECT COUNT(*) as count FROM items');
    if (rows[0].count === 0) {
      await pool.query(`
        INSERT INTO items (name, description) VALUES
        ('Item 1', 'Description de l\\'item 1'),
        ('Item 2', 'Description de l\\'item 2'),
        ('Item 3', 'Description de l\\'item 3')
      `);
      console.log('Données de test insérées');
    }
  } catch (error) {
    console.error('Erreur de connexion à la base de données:', error);
  }
};

// Route de base
app.get('/', (req, res) => {
  res.json({ 
    message: 'API Backend pour Projet-C',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Route pour récupérer tous les items
app.get('/api/data', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM items');
    res.json({ items: rows });
  } catch (error) {
    console.error('Erreur lors de la récupération des données:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Route pour ajouter un item
app.post('/api/data', async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'Le nom est requis' });
    }
    
    const [result] = await pool.query(
      'INSERT INTO items (name, description) VALUES (?, ?)',
      [name, description || '']
    );
    
    res.status(201).json({ 
      id: result.insertId,
      name,
      description
    });
  } catch (error) {
    console.error('Erreur lors de l\'ajout d\'un item:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Initialiser la base de données et démarrer le serveur
initDb().then(() => {
  app.listen(port, () => {
    console.log(`Serveur démarré sur le port ${port} en environnement ${process.env.NODE_ENV || 'development'}`);
  });
});