# Guida per setup k8s cluster

## Setup iniziale macchine
Installare debian o derivati (testato con debian bookworm 12.7)\
- Lasciare vuota la root password
- Create utenza `kubeadmin` uguale su tutte le macchine
- Rimuovere partizione swap durante partizionamento (non supportata da k8s)
- Sullo step 'Softaware selection' installare soltanto 'SSH server' e 'standard system utilities'
> TODO aggiungere step dettagliati

## Setup nodo master
Al termine dell'installazione copiare gli script `master_setup.sh` e `generic_setup.sh` sul nodo master e lanciare `master_setup.sh` con permessi root.\
Verrà installato tutto il necessario per far partire un cluster tramite il tool kubeadm e l'utenza `kubeadmin` sarà abilitata per l'utilizzo di `kubectl`.\
Come ultima cosa copiare gli script di util sull'utenza `kubeadmin`:
```sh
add_user.sh # Per creazione di nuove utenze abilitate all'utilizzo di kubectl
add_worker.sh # Ncessario per aggiungere un nuovo nodo worker al cluster
generic_setup.sh # Dipendenza di add_worker.sh utilizzato per il setup iniziale del nodo
```

## Setup nodi worker
1. Accedere al nodo master con utenza `kubeadmin`
2. Eseguire lo script `add_worker.sh` passando come parametro l'ip locale del nodo da configurare
