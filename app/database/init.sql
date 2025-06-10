-- Création des bases de données pour chaque environnement
CREATE DATABASE IF NOT EXISTS appdb_dev;
CREATE DATABASE IF NOT EXISTS appdb_staging;
CREATE DATABASE IF NOT EXISTS appdb_prod;

-- Utilisateur pour les applications
CREATE USER IF NOT EXISTS 'dbadmin'@'%' IDENTIFIED BY 'ChangeMe123!';

-- Droits pour l'environnement de développement
GRANT ALL PRIVILEGES ON appdb_dev.* TO 'dbadmin'@'%';

-- Droits pour l'environnement de staging
GRANT ALL PRIVILEGES ON appdb_staging.* TO 'dbadmin'@'%';

-- Droits pour l'environnement de production
GRANT ALL PRIVILEGES ON appdb_prod.* TO 'dbadmin'@'%';

-- Appliquer les changements
FLUSH PRIVILEGES;

-- Utiliser la base de données de développement par défaut
USE appdb_dev;

-- Création de la table items
CREATE TABLE IF NOT EXISTS items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Données initiales
INSERT INTO items (name, description) VALUES
('Item 1', 'Description de l\'item 1'),
('Item 2', 'Description de l\'item 2'),
('Item 3', 'Description de l\'item 3');

-- Utiliser la base de données de staging
USE appdb_staging;

-- Création de la table items
CREATE TABLE IF NOT EXISTS items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Données initiales
INSERT INTO items (name, description) VALUES
('Item Staging 1', 'Description de l\'item 1 en staging'),
('Item Staging 2', 'Description de l\'item 2 en staging');

-- Utiliser la base de données de production
USE appdb_prod;

-- Création de la table items
CREATE TABLE IF NOT EXISTS items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Données initiales pour la production
INSERT INTO items (name, description) VALUES
('Produit 1', 'Description du produit 1'),
('Produit 2', 'Description du produit 2');