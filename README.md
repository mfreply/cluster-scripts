# Guida per setup cluster k8s
Insieme di script per la creazione di un cluster k8s con le seguenti caratteristiche:
- Singolo nodo master
- contrainerd CRI
- flannel CNI
- nvidia-device-plugin per discovery di nodi GPU

## Setup iniziale macchine
Installare debian o derivati (testato con debian bookworm 12.7)
- Lasciare vuota la root password (per permettere utilizzo di sudo)
- Create utenza `kubeadmin`
- Rimuovere partizione swap durante partizionamento (non supportata da k8s)
- Sullo step 'Softaware selection' installare soltanto 'SSH server' e 'standard system utilities'
> TODO aggiungere step dettagliati

## Setup nodo master
Al termine dell'installazione entrare con l'utenza creata sul nodo master e eseguire i seguenti comandi.
```sh
mkdir ~/scripts && cd ~/scripts
wget -qO- https://github.com/mfreply/cluster-scripts/archive/master.tar.gz | tar --strip=1 -xvz
chmod +x *.sh
sudo ./master_setup.sh
```

Al termine dell'esecuzione verrà creato un cluster utilizzando il tool kubeadm e l'utenza `kubeadmin` sarà abilitata per l'utilizzo di `kubectl`.

In caso si voglia creare un nuovo utente abilitato all'utilizzo di `kubectl` utilizzare lo script `add_user.sh` fornendo il nome del nuovo utente.

## Setup nodi worker
1. Accedere al nodo master con utenza `kubeadmin` (`sudo su - kubeadm`)
2. Eseguire lo script `add_worker.sh` passando come parametro l'ip locale del nodo da configurare
