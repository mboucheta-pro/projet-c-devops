document.addEventListener('DOMContentLoaded', () => {
  const statusElement = document.getElementById('status');
  const dataContainer = document.getElementById('data-container');
  const environmentElement = document.getElementById('environment');
  const addItemForm = document.getElementById('add-item-form');
  
  // URL de l'API backend (à ajuster selon l'environnement)
  const apiUrl = '/api';
  
  // Vérifier le statut du backend et récupérer l'environnement
  fetch(`${apiUrl}/`)
    .then(response => {
      if (response.ok) {
        statusElement.textContent = 'Connecté';
        statusElement.style.color = 'green';
        return response.json();
      }
      throw new Error('Erreur de connexion');
    })
    .then(data => {
      if (data.environment) {
        environmentElement.textContent = data.environment.toUpperCase();
        document.body.classList.add(`env-${data.environment}`);
      }
    })
    .catch(error => {
      statusElement.textContent = 'Non connecté';
      statusElement.style.color = 'red';
      console.error('Erreur:', error);
    });
  
  // Fonction pour charger les données
  const loadData = () => {
    fetch(`${apiUrl}/data`)
      .then(response => {
        if (response.ok) return response.json();
        throw new Error('Erreur lors de la récupération des données');
      })
      .then(data => {
        dataContainer.innerHTML = '';
        
        if (data.items && data.items.length > 0) {
          const list = document.createElement('div');
          
          data.items.forEach(item => {
            const itemElement = document.createElement('div');
            itemElement.className = 'item';
            itemElement.innerHTML = `
              <h3>${item.name}</h3>
              <p>${item.description || 'Pas de description'}</p>
              <small>Créé le: ${new Date(item.created_at).toLocaleString()}</small>
            `;
            list.appendChild(itemElement);
          });
          
          dataContainer.appendChild(list);
        } else {
          dataContainer.textContent = 'Aucune donnée disponible';
        }
      })
      .catch(error => {
        dataContainer.textContent = 'Erreur lors du chargement des données';
        console.error('Erreur:', error);
      });
  };
  
  // Charger les données au démarrage
  loadData();
  
  // Gérer le formulaire d'ajout
  if (addItemForm) {
    addItemForm.addEventListener('submit', (e) => {
      e.preventDefault();
      
      const nameInput = document.getElementById('item-name');
      const descInput = document.getElementById('item-description');
      
      const name = nameInput.value.trim();
      const description = descInput.value.trim();
      
      if (!name) {
        alert('Le nom est requis');
        return;
      }
      
      fetch(`${apiUrl}/data`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ name, description })
      })
      .then(response => {
        if (response.ok) {
          nameInput.value = '';
          descInput.value = '';
          loadData(); // Recharger les données
          return response.json();
        }
        throw new Error('Erreur lors de l\'ajout');
      })
      .catch(error => {
        console.error('Erreur:', error);
        alert('Erreur lors de l\'ajout de l\'item');
      });
    });
  }
});