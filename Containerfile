FROM registry.access.redhat.com/ubi8/ubi-minimal
RUN microdnf install skopeo jq curl -y
