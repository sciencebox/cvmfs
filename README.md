# cvmfs

Docker image with CVMFS client.


### Usage
- The image only comes with the software. Configuration files for `cvmfs` are not provided in the Docker image;
- Consider using in combination with Helm charts (or similar tools for container configuration) to create the expected configuration files -- See [ScienceBox CVMFS chart](https://github.com/sciencebox/charts/tree/master/cvmfs)

#### Example usage
- Provide the configuration file `/etc/cvmfs/default.local` with relevant configuration parameters (e.g., cache size, http proxy, ...)
- Repository-specific configuration should be provided by creating configuration files at `/etc/cvmfs/config.d/<repo_name>.local`
- Official documentation for the CVMFS client is at https://cvmfs.readthedocs.io/en/stable/cpt-configure.html

- To mount a repoitory, use the command `mount -t cvmfs <repo_name> /cvmfs/<repo_name>`. The folder `/cvmfs/<repo_name>` must exist and be empty;
- Alternatively, use `/etc/fstab` to specify the repositories to be mounted (and mount them with `mount -a`. Example:
    ```
    sft.cern.ch /cvmfs/sft.cern.ch cvmfs defaults,_netdev,nodev 0 0
    sft-nightlies.cern.ch /cvmfs/sft-nightlies.cern.ch cvmfs defaults,_netdev,nodev 0 0
    ```
- The last option is to start the `cvmfs2` process directly:
    ```
    /usr/bin/cvmfs2 -o rw,nodev,_netdev,system_mount,fsname=cvmfs2,allow_other,grab_mountpoint,uid=998,gid=996 sft.cern.ch /cvmfs/sft.cern.ch
    ```

### Special permissions to CVMFS container
The CVMFS container requires a privileged security context and access to the fuse device on the host.
1. For Docker, add the following options to the `docker run` command:
    ```
    --cap-add SYS_ADMIN --device /dev/fuse 
    ```

2. For Kubernetes:
  - In the container spec:
    ```
    securityContext:
      privileged: true
      capabilities:
        add: ["SYS_ADMIN"]

    volumeMounts:
    - name: fuse-device
      mountPath: /dev/fuse
    ```

  - In the volume spec:
    ```
    volumes:
    - name: fuse-device
      hostPath:
        path: /dev/fuse
    ```


### Exposing CVMFS repositories to the host and to other containers
- The CVMFS repositories mounted using the client in the container can be exposed to the host system and to other containers;
- To do so, use bind mount with the host and use 'shared' bind propagation: `--volume /cvmfs:/cvmfs:shared`. Other containers will be able to mount the folder `/cvmfs` from the host.
- Docker documentation on bind propagation: https://docs.docker.com/storage/bind-mounts/#configure-bind-propagation
- Similarly for Kubernetes: https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation
