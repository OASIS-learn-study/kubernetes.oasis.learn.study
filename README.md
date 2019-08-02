# kubernetes.oasis.learn.study

Resources to run Minecraft on a Kubernetes cluster.

## Usage

    kubectl apply -f vanilla-deployment.yaml
    kubectl get pods
    kubectl logs mc-vanilla-...

You can now connect to your Minecraft Server on port 30000 on the Node where Kubernetes scheduled your Pod.

## ToDo

- [ ] Volume
- [ ] Backup?
- [ ] [Healthcheck](https://github.com/itzg/docker-minecraft-server#healthcheck)
- [ ] Sponge
- [ ] https://github.com/OASIS-learn-study/swissarmyknife-minecraft-server
- [ ] https://github.com/itzg/docker-minecraft-server#server-icon
- [ ] custom derived container with JAR etc. pre-loaded

## References

* https://github.com/itzg/docker-minecraft-server
* https://github.com/itzg/docker-minecraft-bedrock-server
* https://github.com/stgarf/minecraft-operator-go
* https://github.com/heptio/tgik/tree/master/episodes/083
