# SeaweedFS soft fork from adhisimon

It just a soft fork of [Chris Lu's SeaweedFS](localhost/chrislusf/seaweedfs) by me. No source code has changed.
The purpose of this fork is just to make it easy for me to
build multiple tags of SeaweedFS container images easily.

## Motivation
SeaweedFS is great.
But looks like sometime [@chrislusf](https://github.com/chrislusf)
too busy and forget sync and releasing
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
I will try to build this tags periodically consistently:
- dev from master branch, beware,
  I don't know if master branch snapshot is stable enough.
  Personally, I just use it for testing something on Admin UI.
- latest release version, eg: 4.18
- latest, will sync with latest release version

I can only build and publish opensource edition of SeaweedFS
because I don't have access to enterprise edition's source code.

See this [github package page](https://github.com/adhisimon/seaweedfs/pkgs/container/seaweedfs) to see all available tags.

