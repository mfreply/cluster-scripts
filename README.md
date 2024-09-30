# Guida per setup k8s cluster

## Setup iniziale macchine
Installare debian o derivati (testato con debian bookworm 12.7)
- Lasciare vuota la root password
- Create utenza `kubeadmin`
- Rimuovere partizione swap durante partizionamento (non supportata da k8s)
- Sullo step 'Softaware selection' installare soltanto 'SSH server' e 'standard system utilities'
> TODO aggiungere step dettagliati

## Setup nodo master
Al termine dell'installazione entrare con l'utenza creata sul nodo master e eseguire i seguenti comandi.
```sh
wget -qO- https://github.com/mfreply/cluster-scripts/archive/refs/tags/v1.tar.gz | tar xvz -C ~
chmod +x ~/cluster-scripts-1/*.sh
sudo ~/cluster-scripts-1/master_setup.sh
```

Al termine dell'esecuzione verrà creato un cluster utilizzando il tool kubeadm e l'utenza `kubeadmin` sarà abilitata per l'utilizzo di `kubectl`.

In caso si voglia creare un nuovo utente abilitato all'utilizzo di `kubectl` utilizzare lo script `add_user.sh` fornendo il nome del nuovo utente.

## Setup nodi worker
1. Accedere al nodo master con utenza `kubeadmin`
2. Eseguire lo script `add_worker.sh` passando come parametro l'ip locale del nodo da configurare
