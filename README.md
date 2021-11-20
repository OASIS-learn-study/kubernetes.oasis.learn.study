# kubernetes.oasis.learn.study

Resources to run Minecraft servers on a Kubernetes cluster
such as Google Kubernetes Engine (GKE) on Google Cloud (GCP). Based on:

* https://github.com/itzg/docker-minecraft-server
* https://github.com/itzg/mc-router

## Usage

Follow https://github.com/vorburger/LearningKubernetes-CodeLabs/blob/develop/docs/install.md#google-kubernetes-engine-gke, and:

    gcloud --project=oasis-learn-study container clusters create-auto cluster1 --zone=europe-west4
    gcloud container clusters get-credentials cluster1 --project=oasis-learn-study --region=europe-west4

    pwgen -s 101 1 | kubectl create secret generic mc-vanilla --from-file=rcon=/dev/stdin
    kubectl apply -f .
    kubectl get service mc-router

You can connect to your Minecraft Server by mapping a hostname such as `oasis.learn.study` to the `EXTERNAL-IP` shown
by the last command above in your local `/etc/hosts` file. You could also add a 2nd Minecraft server (which you also need to
register in your local `/etc/hosts` file again e.g. as this `test2.learn.study`, unless you have DNS) like this:

    sed 's/mc-vanilla/test2/g' vanilla.yaml | sed 's/oasis.learn.study/test2.learn.study/' | kubectl apply -f -

If this doesn't work, the most likely explanation is that you've [run out of quota,
and need to edit to request more](https://console.cloud.google.com/iam-admin/quotas).

### Debug

To troubleshoot & debug startup issues, use:

    kubectl rollout status sts/mc-vanilla
    kubectl describe pod mc-vanilla-0
    kubectl logs -f mc-vanilla-0

    kubectl logs -f mc-router-...

### Fixed IP address

Navigate to https://console.cloud.google.com/networking/addresses/list and click _Reserve_ to turn
the _Ephemeral External IP address_ of the `mc-router` service of type `LoadBalancer` into a fixed static IP,
which you can use in a DNS entry. Further background e.g. on https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip.

### RCON

You can use an [RCON](https://wiki.vg/RCON) client such as [`rcon-cli`](https://github.com/itzg/rcon-cli) to connect to the admin console: (But please note that the RCON protocol is not encrypted, meaning that your passwords are transmitted in plain text to the server. A future version of this project may include a more secure web-based admin console, instead.)

    go get github.com/itzg/rcon-cli
    rcon-cli --host=34.91.151.169 --port=25575 --password=(kubectl get secret mc-vanilla -o jsonpath={.data.rcon} | base64 --decode)
    /list
    /op $YOURSELF

### Stop & Delete

You can stop the server by scaling it down using (and back up with `--replicas=1`):

    kubectl scale statefulset mc-vanilla --replicas=0

To tear down the entire cluster:

    gcloud container clusters delete cluster1

Note that deleting the cluster will obviously delete it's _PersistentVolumes_ and _PersistentVolumeClaims_.
The underlying Persistent Disks (PDs) are not deleted, but worlds won't just nicely come back when re-creating the cluster,
because the PV/PVC-to-PD association will be lost; you would have to manually fix that.  (Don't forget to delete old PDs.)


## Development

### Kubernetes

    kubectl exec mc-vanilla-0 -- mc-monitor status

    kubectl exec mc-vanilla-0 -- bash -c 'echo $RCON_PASSWORD'

    kubectl exec -it mc-vanilla-0 -- bash

**BEWARE** that YAML changes to `env`ironment variables of `itzg/minecraft-server` container will NOT affect existing servers with the image, because many of it's startup parameter environment variables are written into the persistent `/data/server.properties` only when the `StatefulSet` PV is automatically created the first time. To remove that (and **loose your world data**) we have to delete the PVC (which also deletes the PD):

    kubectl delete pvc mc-data-mc-vanilla-0

### Docker

    mkdir /tmp/mcs
    podman run -p 25565:25565 -m 2000M -e EULA=TRUE -e VERSION=1.17.1 -e MODE=1 -v /tmp/mcs:/data:Z --rm --name mcs itzg/minecraft-server:2021.22.0
    podman exec -it mcs bash
    podman rm -f mcs

### Memory Management

The `itzg/minecraft-server` container image uses Java 16 from https://adoptium.net (at least
from its `:2021.22.0`, see https://github.com/itzg/docker-minecraft-server/issues/1054).
This Hotspot image with a vanilla server consumes about 1.3 GB after startup-up, without players.
Even with `-e JVM_XX_OPTS="-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1PeriodicGCInterval=1000 -XX:G1 PeriodicGCSystemLoadThreshold=0" -e INIT_MEMORY=100M -e EULA=TRUE -e VERSION=1.17.1 -e MODE=1` it would not go
lower than these 1.3 GB, even after a `jcmd 37 GC.run` (which also fails with `com.sun.tools.attach.AttachNotSupportedException: Unable to open socket file /proc/37/root/tmp/.java_pid37: target process 37 doesn't respond within 10500ms or HotSpot VM not loaded`, yet still seems to cause GC; see JVM output on Minecraft container log.)
So https://openjdk.java.net/jeps/346 somehow doesn't work here.

The `:2021.22.0-java16-openj9` variant which uses https://www.eclipse.org/openj9/ during the
initial `Preparing spawn area` also goes up to about 1.2 GB, but then (without players) back down to 770 MB!
(With the same settings as above.)  Note that the `INIT_MEMORY=100M` (which translate to -Xms100M) are critical,
because without that, `itzg/minecraft-server` sets `-Xms1G -Xmx1G`, which prevents it to drop to those 770 MB.
(Note that J9's `IdleTuningGcOnIdle` is [the default when running in a docker container](https://www.eclipse.org/openj9/docs/xxidletuninggconidle/).)

With `-e JVM_OPTS="-Xgcpolicy:balanced"` we're even down to ~740 MB for Vanilla 1.17.1 before Players connect.

The first player that connects then pushes us briefly to 1.1 GB, and then back down to around ~840-860 MB or so.
(or even just 820 MB with the `balanced` instead of the default `gencon` GC policy of OpenJ9).

Unfortunately disconnecting the Player doesn't reclaim those 90 MB anymore, and we remain at 860 MB
(or about 850 MB with the `balanced` GC); even after `jcmd 37 GC.run` (which works on OpenJ9 without that error from above).


### Startup Time

[`USE_AIKAR_FLAGS=true`](https://github.com/itzg/docker-minecraft-server#enable-aikars-flags) seems to
boost initial start up time almost 300% - e.g. on a desktop from ~30s to ~12s. (Note that `USE_AIKAR_FLAGS=true`
includes `-XX:+DisableExplicitGC`.)

A larger heap, such as e.g. `-e INIT_MEMORY=1500M -e MAX_MEMORY=1500M` does not appear so signfificantly decrease start-up time.

Using _Shared Classes_, on a persistent volume, may help further (TBD).


## ToDo

- [X] Persistent Volume
- [X] Set appropriate resource constraints
- [X] Locally test: 1. Creative, 2. with all items, 3. with slash commands. Custom server.properties?
- [X] Test PV.. survives YAML delete & apply? Survives cluster delete / apply?

- [ ] JVM monitoring (agent?) with/for StackDriver, separate from `mc-monitor`
- [X] JVM memory up to max container memory, but start with less, and reduce container to 1 GB
- [X] Memory tweaking using e.g. https://github.com/itzg/docker-minecraft-server#enable-aikars-flags
      from https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/,
      or https://github.com/etil2jz/etil-minecraft-flags, compare with https://startmc.sh ?
- [ ] tweak OpenJ9 Nursery GC with `-Xmns` and `-Xmnx` as described in https://steinborn.me/posts/tuning-minecraft-openj9/

- [ ] Scaffold Kubernetes Code Lab for hacking the MCS router to scale up ReplicaSet to 1 if its 0 when connecting
- [ ] https://github.com/itzg/mc-monitor on StackDriver, see
      https://github.com/GoogleCloudPlatform/k8s-stackdriver/tree/master/prometheus-to-sd
      `kubectl exec mc-vanilla-0 -- mc-monitor export-for-prometheus -servers localhost`
- [ ] Scale Down StatefulSet to 0 when no Players for N minutes, query via monitoring!

- [ ] Wildcard DNS - how-to?
- [ ] Add default server, a simple empty world with a shield saying "Wrong server name" (from git, without PV)
- [X] Two servers, with https://github.com/itzg/mc-router/tree/master/docs; no template, just simple sed/rpl
- [ ] Templating, simply using Xtend, from literal objects, later YAML, into files in git - for now (see below).
      Not kpt, Helm, nor Kustomize or CUE or Flux or Nix.
- [ ] gRPC CreateServer ^^^ at runtime with Service Account
- [ ] `/server list`, `/server create`
- [ ] DNS name `oasis.learn.study` instead of IP

- [ ] Try alternative servers than Vanilla, like https://blog.airplane.gg/about/ et al.
- [ ] Logs to file by default? Will grow memory, that's bad. Must be "12 factor", and STDOUT, only.
      Note also https://github.com/itzg/docker-minecraft-server#enabling-rolling-logs
- [ ] decrease start-up time, J9 https://www.eclipse.org/openj9/docs/shrc/
      see also https://www.eclipse.org/openj9/docs/xshareclasses/ ?
      Probably need to make sure they go to /data/ instead of /tmp for this to work.
- [ ] play further with GC and memory management settings, using https://gceasy.io, and
      https://marketplace.eclipse.org/content/ibm-monitoring-and-diagnostic-tools-garbage-collection-and-memory-visualizer-gcmv
      see https://www.eclipse.org/openj9/docs/vgclog/
- [ ] Readyness and liveness are broken and take a very long time, causing Service to not work.
      (NB: If it still doesn't seem work even after `k describe pod mc-vanilla-0` reports Ready is True,
       then it's probably jsut that the service's external IP has changed after a `delete` and re-`apply`...;)
- [ ] Storage Class?
- [ ] read-only FS in MCS container, except `/data`
- [ ] GitOps, `/data` on a git repo, side container; e.g. using something like https://github.com/fvanderbiest/docker-volume-git-backup
- [ ] https://github.com/itzg/docker-bungeecord, with https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft-proxy
- [ ] https://filebrowser.org/features integration
- [ ] Freemium ;) time bomb :) It's an extension of scaling down.
- [ ] https://github.com/OASIS-learn-study/swissarmyknife-minecraft-server
- [ ] https://github.com/itzg/docker-minecraft-server#server-icon
- [ ] custom derived container with JAR etc. pre-loaded
- [ ] replace exposed RCON port by built-in webconsole
- [ ] Bedrock via itzg/docker-minecraft-bedrock-server with https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft-bedrock; or explore https://minecraft.gamepedia.com/Bedrock_Edition_server_software#Protocol_Translator_list

- [ ] Backup via Snapshot of PD
- [ ] Backup, with https://github.com/itzg/docker-mc-backup or à la
      https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft#backups?
- [ ] push to Google Cloud Storage after taking backup, using docker-mc-backup [upcoming Restic support](https://github.com/itzg/docker-mc-backup/pull/3)
- [ ] load from Google Cloud Storage, but using.. [Downloadable WORLD](https://github.com/itzg/docker-minecraft-server#downloadable-world) by GCS URL, or via Restic?
- [X] clean shut-down, already done by itzg/minecraft-server with https://github.com/itzg/mc-server-runner; does not need *exec* [`rcon-cli stop`](https://github.com/itzg/docker-minecraft-server#interacting-with-the-server)
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
