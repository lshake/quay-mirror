## Quay Org / User Mirror

Simple bash script to mirror a set of repositories from a quay organisation or user to a new destination, using skopeo, curl and jq.
The script can be run from the cmd line by setting the appropriate environment variables, or via a kubernetes job.

### Invocation

```shell
export SOURCE='quay-source.example.com'
export DEST='destination.example.com'
export OAUTH='quay_source_oauth_token'
export NAMESPACE='ocp4'
export RETRIES='3'
export ATTEMPTS='3'
export EXTRA_ARGS=''
export AUTHFILE='$(pwd)/auth.json'

podman login --authfile ./auth.json quay-source.example.com
podman login --authfile ./auth.json destination.example.com

./mirror/mirror.sh
```

To run via Kubernetes, update the secrets mirror/mirror-secrets.yaml and registry-secrets.yaml and run kustomize.

```shell
kubectl apply -k ./mirror
```
Ensure that you're authenticated to correct cluster / project.

### Variables

| Name | Example | Description |
| ---- | ------- | ----------- |
| SOURCE | source.example.com | The FQDN of the source quay repository |
| DEST | dest.example.com | The FQDN of the destination repository |
| OAUTH | BKv3qfeIn4vNmALFtLdlZx5WeBVtRSfrqm2EkL5A| An [oauth access token](https://access.redhat.com/documentation/en-us/red_hat_quay/3/html/red_hat_quay_api_guide/using_the_red_hat_quay_api#create_oauth_access_token) for the source quay organisation / user. |
| NAMESPACE | ocp4 | The namespace (Organisation or User) to be mirrored |
| RETRIES | 3 | The number of retires to passed to the skopeo cmd |
| ATTEMPTS | 2 | The number of retries attemped for each repository |
| EXTRA_ARGS | '--debug' | Extra arguments to pass to skopeo |
| AUTHFILE | ${XDG_RUNTIME_DIR}/containers/auth.json | Path to the registry authentication file |

### Notes

1. The script retrives the list of repositories for the supplied namespace via the quay API
2. The tags for each repository are retrieved to ensure we don't try to mirror an empty repository
3. Retries are attempted via by skopeo and, on skopeo failure in the script
