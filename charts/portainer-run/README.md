# Portainer-Run Helm Chart

Deploy [Portainer-Run](https://portainer.ai) on Kubernetes using this Helm chart.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2+
- A running Portainer instance reachable from the cluster

## Install the chart repository

```bash
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
```

## Installing the chart

Create the namespace first:

```bash
kubectl create namespace portainer-run
```

Install with defaults (connects to an in-cluster Portainer instance):

```bash
helm upgrade -i portainer-run portainer/portainer-run -n portainer-run
```

Install pointing to an external Portainer instance with an Anthropic key:

```bash
helm upgrade -i portainer-run portainer/portainer-run -n portainer-run \
  --set config.PORTAINER_URL=https://portainer.example.com:9443 \
  --set secret.anthropicApiKey=sk-ant-...
```

## Testing the chart

```bash
helm install --dry-run --debug portainer-run portainer/portainer-run -n portainer-run
```

## Deleting the chart

```bash
helm delete portainer-run -n portainer-run
kubectl delete namespace portainer-run
```

## Chart configuration

The following table lists configurable parameters and their defaults. The full values file is at `charts/portainer-run/values.yaml`.

### Core

| Parameter | Description | Default |
| - | - | - |
| `replicaCount` | Number of replicas. Keep at 1 unless using `ReadWriteMany` storage. | `1` |
| `image.repository` | Container image repository | `portainer/portainer-run` |
| `image.tag` | Image tag | `""` (uses `appVersion`) |
| `image.pullPolicy` | Image pull policy. Use `IfNotPresent` when pinning a specific tag. | `Always` |
| `imagePullSecrets` | Pull secrets for private registries | `[]` |
| `nameOverride` | Override the chart name | `""` |
| `fullnameOverride` | Override the full release name | `""` |

### Config (ConfigMap / environment variables)

All keys under `config` are rendered into a ConfigMap and injected into the pod via `envFrom`.

| Parameter | Description | Default |
| - | - | - |
| `config.PORTAINER_URL` | URL of the Portainer instance to connect to | `https://portainer.portainer.svc.cluster.local:9443` |
| `config.FEATURE_VIBE_DEPLOY` | Enable the Vibe Deploy feature | `"true"` |
| `config.FEATURE_SIMPLE_DEPLOY` | Enable the Simple Deploy feature | `"false"` |
| `config.FEATURE_MANIFEST_BUILDER` | Enable the Manifest Builder feature | `"false"` |
| `config.FEATURE_CATALOGUE` | Enable the Catalogue feature | `"false"` |
| `config.FEATURE_SECRETS` | Enable the Secrets feature | `"false"` |
| `config.TEMPLATE_URL` | URL of a custom template JSON file | `""` |
| `config.BASE_DOMAIN` | Base domain for generated app URLs | `""` |
| `config.OPENAI_MODEL` | OpenAI model to use | `""` |
| `config.CACHE_DIR` | Directory for caching data inside the container | `""` |

### Secrets

To use a pre-existing Secret instead of letting the chart create one, set `secret.existingSecret` to its name. The Secret must contain the key `ENCRYPTION_KEY` and optionally `ANTHROPIC_API_KEY` and `OPENAI_API_KEY`.

| Parameter | Description | Default |
| - | - | - |
| `secret.existingSecret` | Name of a pre-existing Secret to use instead of creating one | `""` |
| `secret.encryptionKey` | Key used to encrypt stored Git credentials at rest (min 32 chars). Auto-generated if left empty. | `""` |
| `secret.anthropicApiKey` | Anthropic (Claude) API key | `""` |
| `secret.openaiApiKey` | OpenAI API key | `""` |

> **Warning:** The `encryptionKey` is set once and never rotated. Changing it after first install will make the stored database unreadable. Generate a key manually with `openssl rand -hex 32` if you want to manage it yourself.

### TLS

By default Portainer-Run generates a self-signed certificate at startup. To serve a trusted certificate, create a `kubernetes.io/tls` Secret and reference it below.

| Parameter | Description | Default |
| - | - | - |
| `tls.existingSecret` | Name of a `kubernetes.io/tls` Secret containing the certificate | `""` |
| `tls.mountPath` | Mount path for the TLS secret inside the container | `/certs` |
| `tls.certKey` | Key in the Secret that holds the certificate | `tls.crt` |
| `tls.keyKey` | Key in the Secret that holds the private key | `tls.key` |

### Service

| Parameter | Description | Default |
| - | - | - |
| `service.type` | Service type: `ClusterIP`, `NodePort`, or `LoadBalancer` | `ClusterIP` |
| `service.httpsPort` | HTTPS port exposed by the Service | `443` |
| `service.httpPort` | HTTP port exposed by the Service (redirects to HTTPS) | `80` |
| `service.annotations` | Annotations to add to the Service (e.g. ingress-controller backend protocol) | `{}` |

### Ingress

The backend serves HTTPS only; HTTP redirects to HTTPS. When using an ingress controller, annotate the **Service** (not the Ingress) to tell the controller to use HTTPS when connecting to the backend:

- **Traefik**: `traefik.ingress.kubernetes.io/service.serverstransport: "<namespace>-<name>@kubernetescrd"` (also requires a `ServersTransport` CRD with `insecureSkipVerify: true`)
- **nginx**: `nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"`

| Parameter | Description | Default |
| - | - | - |
| `ingress.enabled` | Create an Ingress resource | `false` |
| `ingress.ingressClassName` | Ingress class name (e.g. `nginx`, `traefik`) | `""` |
| `ingress.annotations` | Annotations to add to the Ingress | `{}` |
| `ingress.hosts[].host` | Hostname for the Ingress rule | `portainer-run.chart-example.local` |
| `ingress.hosts[].paths[].path` | Path for the Ingress rule | `/` |
| `ingress.hosts[].paths[].pathType` | Path type | `Prefix` |
| `ingress.tls` | TLS configuration for the Ingress | `[]` |

### Persistence

| Parameter | Description | Default |
| - | - | - |
| `persistence.enabled` | Enable data persistence via a PVC | `true` |
| `persistence.size` | PVC size | `1Gi` |
| `persistence.accessMode` | PVC access mode. Use `ReadWriteMany` if scaling beyond 1 replica. | `ReadWriteOnce` |
| `persistence.storageClass` | StorageClass for the PVC. Empty string uses the cluster default. | `""` |
| `persistence.existingClaim` | Name of a pre-existing PVC to use | `""` |
| `persistence.annotations` | Annotations to add to the PVC | `{}` |
| `persistence.mountPath` | Mount path inside the container | `/app/data` |

### DNS

| Parameter | Description | Default |
| - | - | - |
| `dnsConfig.enabled` | Inject a custom `dnsConfig` into the pod | `true` |
| `dnsConfig.ndots` | `ndots` value to reduce unnecessary DNS search expansion for in-cluster hostnames | `"1"` |
| `dnsConfig.nameservers` | Additional nameservers | `[]` |
| `dnsConfig.searches` | Additional search domains | `[]` |
| `dnsConfig.options` | Additional DNS options | `[]` |

### Scheduling

| Parameter | Description | Default |
| - | - | - |
| `nodeSelector` | Node selector labels | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity/anti-affinity rules | `{}` |

### Pod metadata

| Parameter | Description | Default |
| - | - | - |
| `podAnnotations` | Annotations to add to the pod | `{}` |
| `podLabels` | Extra labels to add to the pod | `{}` |
| `podSecurityContext` | Pod-level security context | `{}` |
| `securityContext` | Container-level security context | `{}` |

### Resources and probes

| Parameter | Description | Default |
| - | - | - |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `64Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `livenessProbe` | Liveness probe configuration | HTTPS GET `/config` after 15 s |
| `readinessProbe` | Readiness probe configuration | HTTPS GET `/config` after 10 s |

### Extra environment variables

`extraEnv` accepts a list of `env` entries supporting both plain `value` and `valueFrom` (e.g. `secretKeyRef`, `configMapKeyRef`):

```yaml
extraEnv:
  - name: MY_VAR
    value: "hello"
  - name: MY_SECRET
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: my-key
```

## Example: Traefik ingress with trusted TLS

```bash
# 1. Create a TLS secret
kubectl create secret tls portainer-run-tls \
  --cert=tls.crt --key=tls.key \
  -n portainer-run

# 2. Create a ServersTransport to allow Traefik to connect to the self-signed backend cert
kubectl apply -f - <<EOF
apiVersion: traefik.io/v1alpha1
kind: ServersTransport
metadata:
  name: portainer-run-transport
  namespace: portainer-run
spec:
  insecureSkipVerify: true
EOF

# 3. Install the chart
helm upgrade -i portainer-run portainer/portainer-run -n portainer-run \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=traefik \
  --set "ingress.hosts[0].host=portainer-run.example.com" \
  --set "ingress.tls[0].secretName=portainer-run-tls" \
  --set "ingress.tls[0].hosts[0]=portainer-run.example.com" \
  --set "service.annotations.traefik\.ingress\.kubernetes\.io/service\.serverstransport=portainer-run-portainer-run-transport@kubernetescrd" \
  --set tls.existingSecret=portainer-run-tls
```
