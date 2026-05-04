# SeaweedFS soft fork from adhisimon

It just a soft fork of [Chris Lu's SeaweedFS](localhost/chrislusf/seaweedfs) by me. No source code has changed.
The purpose of this fork is just to make it easy for me to
build multiple tags of SeaweedFS container images easily.

## Motivation
SeaweedFS is great.
But looks like sometime [@chrislusf](https://github.com/chrislusf)
too busy and forget sync and releasing
latest container tag to latest release.

<<<<<<< HEAD
## Container repository
You can pull my build by:
=======
![SeaweedFS Logo](https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/note/seaweedfs.png)

<h2 align="center"><a href="https://www.patreon.com/seaweedfs">Sponsor SeaweedFS via Patreon</a></h2>

SeaweedFS is an independent Apache-licensed open source project with its ongoing development made
possible entirely thanks to the support of these awesome [backers](https://github.com/seaweedfs/seaweedfs/blob/master/backers.md).
If you'd like to grow SeaweedFS even stronger, please consider joining our
<a href="https://www.patreon.com/seaweedfs">sponsors on Patreon</a>.

Your support will be really appreciated by me and other supporters!

<!--
<h4 align="center">Platinum</h4>

<p align="center">
  <a href="" target="_blank">
    Add your name or icon here
  </a>
</p>
-->

### Gold Sponsors
[![nodion](https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/note/sponsor_nodion.png)](https://www.nodion.com)
[![piknik](https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/note/piknik.png)](https://www.piknik.com)
[![keepsec](https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/note/keepsec.png)](https://www.keepsec.ca)

---

- [Download Binaries for different platforms](https://github.com/seaweedfs/seaweedfs/releases/latest)
- [SeaweedFS on Slack](https://join.slack.com/t/seaweedfs/shared_invite/enQtMzI4MTMwMjU2MzA3LTEyYzZmZWYzOGQ3MDJlZWMzYmI0OTE4OTJiZjJjODBmMzUxNmYwODg0YjY3MTNlMjBmZDQ1NzQ5NDJhZWI2ZmY)
- [SeaweedFS on Twitter](https://twitter.com/SeaweedFS)
- [SeaweedFS on Telegram](https://t.me/Seaweedfs) 
- [SeaweedFS on Reddit](https://www.reddit.com/r/SeaweedFS/)
- [SeaweedFS Mailing List](https://groups.google.com/d/forum/seaweedfs)
- [Wiki Documentation](https://github.com/seaweedfs/seaweedfs/wiki)
- [SeaweedFS White Paper](https://github.com/seaweedfs/seaweedfs/wiki/SeaweedFS_Architecture.pdf)
- [SeaweedFS Introduction Slides 2025.5](https://docs.google.com/presentation/d/1tdkp45J01oRV68dIm4yoTXKJDof-EhainlA0LMXexQE/edit?usp=sharing)
- [SeaweedFS Introduction Slides 2021.5](https://docs.google.com/presentation/d/1DcxKWlINc-HNCjhYeERkpGXXm6nTCES8mi2W5G0Z4Ts/edit?usp=sharing)
- [SeaweedFS Introduction Slides 2019.3](https://www.slideshare.net/chrislusf/seaweedfs-introduction)

Table of Contents
=================

* [Quick Start](#quick-start)
    * [Quick Start with weed mini](#quick-start-with-weed-mini)
    * [Quick Start for S3 API on Docker](#quick-start-for-s3-api-on-docker)
* [Introduction](#introduction)
* [Features](#features)
    * [Additional Features](#additional-features)
    * [Filer Features](#filer-features)
* [Example: Using Seaweed Object Store](#example-using-seaweed-object-store)
* [Architecture](#object-store-architecture)
* [Compared to Other File Systems](#compared-to-other-file-systems)
    * [Compared to HDFS](#compared-to-hdfs)
    * [Compared to GlusterFS, Ceph](#compared-to-glusterfs-ceph)
    * [Compared to GlusterFS](#compared-to-glusterfs)
    * [Compared to Ceph](#compared-to-ceph)
    * [Compared to Minio](#compared-to-minio)
* [Dev Plan](#dev-plan)
* [Installation Guide](#installation-guide)
* [Disk Related Topics](#disk-related-topics)
* [Benchmark](#benchmark)
* [Enterprise](#enterprise)
* [License](#license)

# Quick Start #


## Quick Start with weed mini ##

Download the latest binary from https://github.com/seaweedfs/seaweedfs/releases and unzip the single `weed` (or `weed.exe`) file, or run `go install github.com/seaweedfs/seaweedfs/weed@latest`. Then start a ready-to-use S3 object store with credentials and a pre-created bucket in one command:

```bash
AWS_ACCESS_KEY_ID=admin \
AWS_SECRET_ACCESS_KEY=secret \
S3_BUCKET=my-bucket \
./weed mini -dir=/data
```

That's it — the S3 endpoint is at http://localhost:8333, `my-bucket` already exists, and `admin`/`secret` are valid credentials. `S3_BUCKET` accepts a comma-separated list (e.g. `raw,processed`); use `S3_TABLE_BUCKET` for S3 Tables (Iceberg) buckets. Drop any of the env vars to skip that piece (no AWS keys → S3 runs in unauthenticated "Allow All" mode for development).

The same command starts everything else too:
- **S3 Endpoint**: http://localhost:8333
- **Master UI**: http://localhost:9333
- **Volume Server**: http://localhost:9340
- **Filer UI**: http://localhost:8888
- **WebDAV**: http://localhost:7333
- **Admin UI**: http://localhost:23646

> macOS: if the binary is quarantined, run `xattr -d com.apple.quarantine ./weed` first.

Perfect for development, testing, learning SeaweedFS, and single-node deployments. To scale out, add more volume servers by running `weed volume -dir="/some/data/dir2" -master="<master_host>:9333" -port=8081` locally, on another machine, or on thousands of machines.

## Quick Start for S3 API on Docker ##

```bash
docker run -p 8333:8333 \
  -e AWS_ACCESS_KEY_ID=admin \
  -e AWS_SECRET_ACCESS_KEY=secret \
  -e S3_BUCKET=my-bucket \
  chrislusf/seaweedfs
```

Same behavior as the `weed mini` command above — the S3 endpoint is at http://localhost:8333 with `my-bucket` pre-created. Drop the env vars to run anonymously for development.

# Introduction #

SeaweedFS is a simple and highly scalable distributed file system. There are two objectives:

1. to store billions of files!
2. to serve the files fast!

SeaweedFS started as a blob store to handle small files efficiently. 
Instead of managing all file metadata in a central master, 
the central master only manages volumes on volume servers, 
and these volume servers manage files and their metadata. 
This relieves concurrency pressure from the central master and spreads file metadata into volume servers, 
allowing faster file access (O(1), usually just one disk read operation).

There is only 40 bytes of disk storage overhead for each file's metadata. 
It is so simple with O(1) disk reads that you are welcome to challenge the performance with your actual use cases.

SeaweedFS started by implementing [Facebook's Haystack design paper](http://www.usenix.org/event/osdi10/tech/full_papers/Beaver.pdf). 
Also, SeaweedFS implements erasure coding with ideas from 
[f4: Facebook’s Warm BLOB Storage System](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-muralidhar.pdf), and has a lot of similarities with [Facebook’s Tectonic Filesystem](https://www.usenix.org/system/files/fast21-pan.pdf) and [Google's Colossus File System](https://cloud.google.com/blog/products/storage-data-transfer/a-peek-behind-colossus-googles-file-system)

On top of the blob store, optional [Filer] can support directories and POSIX attributes. 
Filer is a separate linearly-scalable stateless server with customizable metadata stores, 
e.g., MySql, Postgres, Redis, Cassandra, HBase, Mongodb, Elastic Search, LevelDB, RocksDB, Sqlite, MemSql, TiDB, Etcd, CockroachDB, YDB, etc.

SeaweedFS can transparently integrate with the cloud. 
With hot data on local cluster, and warm data on the cloud with O(1) access time, 
SeaweedFS can achieve both fast local access time and elastic cloud storage capacity.
What's more, the cloud storage access API cost is minimized. 
Faster and cheaper than direct cloud storage!

SeaweedFS also ships a built-in **Iceberg REST Catalog**, turning the same cluster into a self-contained lakehouse.
Spark, Trino, Dremio, DuckDB, and RisingWave can query Iceberg tables directly — no Hive Metastore, Glue, or
external catalog service required. Storage and table metadata live in one system, simplifying on-prem and
small-team analytics stacks.

[Back to TOC](#table-of-contents)

# Features #
## Additional Blob Store Features ##
* Support different replication levels, with rack and data center aware.
* Automatic master servers failover - no single point of failure (SPOF).
* Automatic compression depending on file MIME type.
* Automatic compaction to reclaim disk space after deletion or update.
* [Automatic entry TTL expiration][VolumeServerTTL].
* Flexible Capacity Expansion: Any server with some disk space can add to the total storage space.
* Adding/Removing servers does **not** cause any data re-balancing unless triggered by admin commands.
* Optional picture resizing.
* Support ETag, Accept-Range, Last-Modified, etc.
* Support in-memory/leveldb/readonly mode tuning for memory/performance balance.
* Support rebalancing the writable and readonly volumes.
* [Customizable Multiple Storage Tiers][TieredStorage]: Customizable storage disk types to balance performance and cost.
* [Transparent cloud integration][CloudTier]: unlimited capacity via tiered cloud storage for warm data.
* [Erasure Coding for warm storage][ErasureCoding]  Rack-Aware 10.4 erasure coding reduces storage cost and increases availability. Enterprise version can customize EC ratio.

[Back to TOC](#table-of-contents)

## Filer Features ##
* [Filer server][Filer] provides "normal" directories and files via HTTP.
* [File TTL][FilerTTL] automatically expires file metadata and actual file data.
* [Mount filer][Mount] reads and writes files directly as a local directory via FUSE.
* [Filer Store Replication][FilerStoreReplication] enables HA for filer meta data stores.
* [Active-Active Replication][ActiveActiveAsyncReplication] enables asynchronous one-way or two-way cross cluster continuous replication.
* [Amazon S3 compatible API][AmazonS3API] accesses files with S3 tooling.
* [Hadoop Compatible File System][Hadoop] accesses files from Hadoop/Spark/Flink/etc or even runs HBase.
* [Async Replication To Cloud][BackupToCloud] has extremely fast local access and backups to Amazon S3, Google Cloud Storage, Azure, BackBlaze.
* [WebDAV] accesses as a mapped drive on Mac and Windows, or from mobile devices.
* [AES256-GCM Encrypted Storage][FilerDataEncryption] safely stores the encrypted data.
* [Super Large Files][SuperLargeFiles] stores large or super large files in tens of TB.
* [Cloud Drive][CloudDrive] mounts cloud storage to local cluster, cached for fast read and write with asynchronous write back.
* [Gateway to Remote Object Store][GatewayToRemoteObjectStore] mirrors bucket operations to remote object storage, in addition to [Cloud Drive][CloudDrive]

## Data Lakehouse Features ##
* [S3 Table Buckets][S3TableBucket] expose a dedicated namespace for Iceberg tables with strict layout validation.
* Built-in [Iceberg REST Catalog][IcebergCatalog] runs alongside the S3 endpoint — no external metastore needed.
* Native integrations with [Apache Spark][SparkIceberg], [Trino][TrinoIceberg], [Dremio][DremioIceberg], [DuckDB][DuckDBIceberg], and [RisingWave][RisingWaveIceberg].
* [Automated table maintenance][IcebergMaintenance]: compaction, snapshot expiration, orphan removal, manifest rewriting.
* Granular IAM at the bucket, namespace, and table level via standard S3 bucket policies.

## Kubernetes ##
* [Kubernetes CSI Driver][SeaweedFsCsiDriver] A Container Storage Interface (CSI) Driver. [![Docker Pulls](https://img.shields.io/docker/pulls/chrislusf/seaweedfs-csi-driver.svg?maxAge=4800)](https://hub.docker.com/r/chrislusf/seaweedfs-csi-driver/)
* [SeaweedFS Operator](https://github.com/seaweedfs/seaweedfs-operator)

[Filer]: https://github.com/seaweedfs/seaweedfs/wiki/Directories-and-Files
[SuperLargeFiles]: https://github.com/seaweedfs/seaweedfs/wiki/Data-Structure-for-Large-Files
[Mount]: https://github.com/seaweedfs/seaweedfs/wiki/FUSE-Mount
[AmazonS3API]: https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API
[BackupToCloud]: https://github.com/seaweedfs/seaweedfs/wiki/Async-Replication-to-Cloud
[Hadoop]: https://github.com/seaweedfs/seaweedfs/wiki/Hadoop-Compatible-File-System
[WebDAV]: https://github.com/seaweedfs/seaweedfs/wiki/WebDAV
[ErasureCoding]: https://github.com/seaweedfs/seaweedfs/wiki/Erasure-coding-for-warm-storage
[TieredStorage]: https://github.com/seaweedfs/seaweedfs/wiki/Tiered-Storage
[CloudTier]: https://github.com/seaweedfs/seaweedfs/wiki/Cloud-Tier
[FilerDataEncryption]: https://github.com/seaweedfs/seaweedfs/wiki/Filer-Data-Encryption
[FilerTTL]: https://github.com/seaweedfs/seaweedfs/wiki/Filer-Stores
[VolumeServerTTL]: https://github.com/seaweedfs/seaweedfs/wiki/Store-file-with-a-Time-To-Live
[SeaweedFsCsiDriver]: https://github.com/seaweedfs/seaweedfs-csi-driver
[ActiveActiveAsyncReplication]: https://github.com/seaweedfs/seaweedfs/wiki/Filer-Active-Active-cross-cluster-continuous-synchronization
[FilerStoreReplication]: https://github.com/seaweedfs/seaweedfs/wiki/Filer-Store-Replication
[KeyLargeValueStore]: https://github.com/seaweedfs/seaweedfs/wiki/Filer-as-a-Key-Large-Value-Store
[CloudDrive]: https://github.com/seaweedfs/seaweedfs/wiki/Cloud-Drive-Architecture
[GatewayToRemoteObjectStore]: https://github.com/seaweedfs/seaweedfs/wiki/Gateway-to-Remote-Object-Storage
[S3TableBucket]: https://github.com/seaweedfs/seaweedfs/wiki/S3-Table-Bucket
[IcebergCatalog]: https://github.com/seaweedfs/seaweedfs/wiki/SeaweedFS-Iceberg-Catalog
[IcebergMaintenance]: https://github.com/seaweedfs/seaweedfs/wiki/Iceberg-Table-Maintenance
[SparkIceberg]: https://github.com/seaweedfs/seaweedfs/wiki/Spark-Iceberg-Integration
[TrinoIceberg]: https://github.com/seaweedfs/seaweedfs/wiki/Trino-Iceberg-Integration
[DremioIceberg]: https://github.com/seaweedfs/seaweedfs/wiki/Dremio-Iceberg-Integration
[DuckDBIceberg]: https://github.com/seaweedfs/seaweedfs/wiki/DuckDB-Iceberg-Integration
[RisingWaveIceberg]: https://github.com/seaweedfs/seaweedfs/wiki/RisingWave-Iceberg-Integration


[Back to TOC](#table-of-contents)

## Example: Using Seaweed Blob Store ##

By default, the master node runs on port 9333, and the volume nodes run on port 8080.
Let's start one master node, and two volume nodes on port 8080 and 8081. Ideally, they should be started from different machines. We'll use localhost as an example.

SeaweedFS uses HTTP REST operations to read, write, and delete. The responses are in JSON or JSONP format.

### Start Master Server ###
>>>>>>> upstream/master

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
- release version, eg: 4.18, 4.19
- latest, will sync with latest release version

I can only build and publish opensource edition of SeaweedFS
because I don't have access to enterprise edition's source code.

See this [github package page](https://github.com/adhisimon/seaweedfs/pkgs/container/seaweedfs) to see all available tags.

