
# kubernetes.oasis.learn.study

Resources to run Minecraft on a Kubernetes cluster.


## Usage

This currently uses a Kubernetes Volume of type hostPath, and as such is only really suitable for simple single node clusters:

    sudo mkdir -p /kube-volumes/minecraft/mc-vanilla-1/
    sudo mkdir -p /kube-volumes/minecraft-backup/mc-vanilla-1/

    kubectl apply -f vanilla-deployment.yaml
    kubectl get pods
    kubectl logs mc-vanilla-...
    kubectl logs mc-vanilla-... mc-backup

You can now connect to your Minecraft Server on port 30000 on the Node where Kubernetes scheduled your Pod.


## ToDo

- [X] Volume
- [X] [Backup](https://github.com/itzg/docker-mc-backup)
- [ ] push to Google Cloud Storage after taking backup, using docker-mc-backup [upcoming Restic support](https://github.com/itzg/docker-mc-backup/pull/3)
- [ ] easy multi-server templating, using.. Kustomize or Helm?
- [ ] clean shut-down (probably?) needs *exec* [`rcon-cli stop`](https://github.com/itzg/docker-minecraft-server#interacting-with-the-server), and must cause it to take a backup..
- [ ] load from Google Cloud Storage, but using.. [Downloadable WORLD](https://github.com/itzg/docker-minecraft-server#downloadable-world) by GCS URL, or via Restic?
- [X] [Healthcheck](https://github.com/itzg/docker-minecraft-server#healthcheck)
- [ ] Sponge
- [ ] https://github.com/OASIS-learn-study/swissarmyknife-minecraft-server
- [ ] mc-router
- [ ] https://github.com/itzg/docker-minecraft-server#server-icon
- [ ] custom derived container with JAR etc. pre-loaded
- [ ] Bedrock via itzg/docker-minecraft-bedrock-server and (or?) explore https://minecraft.gamepedia.com/Bedrock_Edition_server_software#Protocol_Translator_list


## References

### Servers

* https://github.com/itzg/docker-minecraft-server
* https://github.com/itzg/docker-mc-backup
* https://github.com/itzg/mc-router
* https://github.com/itzg/docker-minecraft-bedrock-server
* https://github.com/itzg/docker-bungeecord

### Kubernetes Operators

* https://github.com/stgarf/minecraft-operator-go
* https://github.com/jbeda/kinecraft
* https://github.com/heptio/tgik/tree/master/episodes/083
* https://github.com/fabianvf/game-server-operator
