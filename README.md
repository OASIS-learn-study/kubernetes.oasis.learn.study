# kubernetes.oasis.learn.study

Resources to run Minecraft on a Kubernetes cluster.


## Usage

This currently uses a Kubernetes Volume of type hostPath, and as such is only really suitable for simple single node clusters:

    sudo mkdir -p /kube-volumes/minecraft/mc-vanilla-1/

    kubectl apply -f vanilla-deployment.yaml
    kubectl get pods
    kubectl logs mc-vanilla-...

You can now connect to your Minecraft Server on port 30000 on the Node where Kubernetes scheduled your Pod.


## ToDo

- [X] Volume
- [ ] [Backup](https://github.com/itzg/docker-mc-backup)
- [ ] load from Google Cloud Storage, copy backups to Google Cloud Storage
- [ ] [Healthcheck](https://github.com/itzg/docker-minecraft-server#healthcheck)
- [ ] Sponge
- [ ] https://github.com/OASIS-learn-study/swissarmyknife-minecraft-server
- [ ] mc-router
- [ ] https://github.com/itzg/docker-minecraft-server#server-icon
- [ ] custom derived container with JAR etc. pre-loaded


## References

* https://github.com/itzg/docker-minecraft-server
* https://github.com/itzg/docker-minecraft-bedrock-server
* https://github.com/stgarf/minecraft-operator-go
* https://github.com/heptio/tgik/tree/master/episodes/083
* https://github.com/itzg/mc-router
