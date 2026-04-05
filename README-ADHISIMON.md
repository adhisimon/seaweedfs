# SeaweedFS soft fork from adhisimon

It just a soft fork of [Chris Lu](https://github.com/chrislusf) [SeaweedFS](localhost/chrislusf/seaweedfs) by me. No source code has changed.
The purpose of this fork is just to make it easy for me to
build multiple tags of SeaweedFS container images easily.

## Motivation
SeaweedFS is great.
But looks like sometime @chrislusf too busy and forget sync and releasing
latest container tag to latest release.

## Container repository
You can pull my build by:

```
docker pull ghcr.io/adhisimon/seaweedfs:latest
```

or

```
podman pull ghcr.io/adhisimon/seaweedfs:latest
```

If you use my build, please star this repository
so I know that someone else use my build.

## Tags
I will try to build this tags consistently:
- dev (from master branch)
- latest release version, eg: 4.18
- latest (will sync with latest release version)
