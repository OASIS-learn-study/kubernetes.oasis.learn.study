# kubernetes.oasis.learn.study

Resources to run Minecraft on a Kubernetes cluster.


## Usage

https://github.com/vorburger/LearningKubernetes-CodeLabs/blob/develop/docs/install.md#google-kubernetes-engine-gke

~~This currently uses a Kubernetes Volume of type hostPath, and as such is only really suitable for simple single node clusters:~~

    gcloud --project=oasis-learn-study container clusters create-auto cluster1 --zone=europe-west4
    gcloud container clusters get-credentials cluster1 --project=oasis-learn-study --region=europe-west4

    kubectl apply -f vanilla.yaml
    kubectl get service mc-vanilla

    kubectl rollout status sts/mc-vanilla
    kubectl describe pod mc-vanilla-0
    kubectl logs -f mc-vanilla-0

You can now connect to your Minecraft Server on port 30000 on the Node where Kubernetes scheduled your Pod. To tear down:

    gcloud container clusters delete cluster1

Note that deleting the cluster will obviously delete it's _PersistentVolumes_ and _PersistentVolumeClaims_.
_TODO: **Verify this!** But the underlying Persistent Disks (PDs) are not deleted, so worlds come back when recreating the cluster!_


## Development

### Kubernetes

    kubectl exec mc-vanilla-0 -- mc-monitor status

### Docker

    podman run -p 25565:25565 -e EULA=TRUE -e VERSION=1.17.1 -e MODE=CREATIVE --rm --name mcs itzg/minecraft-server

    podman rm -f mcs


## ToDo

- [X] Persistent Volume
- [X] Set appropriate resource constraints
- [ ] Readyness and liveness are broken and take a very long time, causing Service to not work.
      (NB: If it still doesn't seem work even after `k describe pod mc-vanilla-0` reports Ready is True,
       then it's probably jsut that the service's external IP has changed after a `delete` and re-`apply`...;)
- [ ] Locally test: 1. Creative, 2. with all items, 3. with slash commands. Custom server.properties?
- [ ] Test PV.. survives YAML delete & apply? Survives cluster delete / apply?
- [ ] Storage Class?
- [ ] DNS names instead of IP
- [ ] Two servers, with https://github.com/itzg/mc-router/tree/master/docs
- [ ] https://github.com/itzg/docker-bungeecord, with https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft-proxy
- [ ] Templating, simply using Xtend, from literal objects, later YAML, into files in git - for now (see below).
      Not Helm, nor Kustomize or CUE or Flux or Nix.
- [ ] gRPC CreateServer ^^^ at runtime with Service Account
- [ ] `/server list`, `/server create`
- [ ] https://github.com/itzg/mc-monitor on StackDriver, see
      https://github.com/GoogleCloudPlatform/k8s-stackdriver/tree/master/prometheus-to-sd
      `kubectl exec mc-vanilla-0 -- mc-monitor export-for-prometheus -servers localhost`
- [ ] Scale Down StatefulSet to 0 when no Players for N minutes, query via monitoring!
- [ ] JVM monitoring, separate from `mc-monitor`
- [ ] Freemium ;) time bomb :) It's an extension of scaling down.
- [ ] https://github.com/OASIS-learn-study/swissarmyknife-minecraft-server
- [ ] https://github.com/itzg/docker-minecraft-server#server-icon
- [ ] custom derived container with JAR etc. pre-loaded
- [ ] Bedrock via itzg/docker-minecraft-bedrock-server with https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft-bedrock; or explore https://minecraft.gamepedia.com/Bedrock_Edition_server_software#Protocol_Translator_list

- [ ] Backup via Snapshot of PD
- [ ] Backup, with https://github.com/itzg/docker-mc-backup or à la
      https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft#backups?
- [ ] push to Google Cloud Storage after taking backup, using docker-mc-backup [upcoming Restic support](https://github.com/itzg/docker-mc-backup/pull/3)
- [ ] load from Google Cloud Storage, but using.. [Downloadable WORLD](https://github.com/itzg/docker-minecraft-server#downloadable-world) by GCS URL, or via Restic?
- [X] clean shut-down, already done by itzg/minecraft-server with https://github.com/itzg/mc-server-runner; does not need *exec* [`rcon-cli stop`](https://github.com/itzg/docker-minecraft-server#interacting-with-the-server) ~~and must cause it to take a backup~~
- [X] [Healthcheck](https://github.com/itzg/docker-minecraft-server#healthcheck)


## References

### Servers

* https://github.com/itzg/docker-minecraft-server
* https://github.com/itzg/docker-mc-backup
* https://github.com/itzg/mc-router
* https://github.com/itzg/docker-minecraft-bedrock-server
* https://github.com/itzg/docker-bungeecord

### Kubernetes YAML

* https://github.com/itzg/docker-minecraft-server/blob/master/examples/k8s/
* https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft/templates
* https://github.com/itzg/minecraft-server-charts/issues/84

### Kubernetes Operators

* https://github.com/stgarf/minecraft-operator-go
* https://github.com/jbeda/kinecraft
* https://github.com/heptio/tgik/tree/master/episodes/083
* https://github.com/fabianvf/game-server-operator
