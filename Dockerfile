# syntax=docker.io/docker/dockerfile:1.25.0

ARG BASE_IMAGE=docker.io/rockylinux/rockylinux:10.2.20260525.0

FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE} AS base

# helm 的二进制不在 GitHub Release 资产里，只发布在 get.helm.sh
ARG HELM_URL=https://get.helm.sh
# ARG HELM_URL=https://files.m.daocloud.io/get.helm.sh

# helm
# https://github.com/helm/helm/releases
ARG INST_HELM_V=v4.3.2

ARG VENDOR_ARCHES="amd64 arm64"

ENV \
    HELM_URL=${HELM_URL} \
    INST_HELM_V=${INST_HELM_V} \
    VENDOR_ARCHES=${VENDOR_ARCHES}

# ---------------------------------------------------------------------------
# binaries
#    /cpaas/vendor/helm/<arch>/{helm,LICENSE}
#    /cpaas/vendor/helm/<arch>/{helm,LICENSE}.sha256sum
#    /cpaas/vendor/helm/<arch>/helm-<ver>-linux-<arch>.tar.gz.sha256
#
# ---------------------------------------------------------------------------
FROM --platform=${BUILDPLATFORM} base AS binaries

RUN --mount=type=cache,target=/tmp,id=build-tmp,sharing=locked \
    set -eu \
    && for arch in ${VENDOR_ARCHES}; do \
    tarball="helm-${INST_HELM_V}-linux-${arch}.tar.gz" ; \
    dst="/cpaas/vendor/helm/${arch}" ; \
    curl --fail -sL -m 300 --retry 3 --retry-delay 5 \
    "${HELM_URL}/${tarball}" -o "/tmp/${tarball}" ; \
    curl --fail -sL -m 60 --retry 3 --retry-delay 5 \
    "${HELM_URL}/${tarball}.sha256sum" -o "/tmp/${tarball}.sha256sum" ; \
    echo "$(cut -d' ' -f1 "/tmp/${tarball}.sha256sum")  /tmp/${tarball}" \
    | sha256sum --check --strict - ; \
    mkdir -p "${dst}" ; \
    tar zxf "/tmp/${tarball}" -C "${dst}" --strip-components=1 \
    "linux-${arch}/helm" "linux-${arch}/LICENSE" ; \
    chmod +x "${dst}/helm" ; \
    ( cd "${dst}" && for f in * ; do sha256sum "${f}" > "${f}.sha256sum" ; done ) ; \
    cp "/tmp/${tarball}.sha256sum" "${dst}/${tarball}.sha256" ; \
    done

RUN set -eu \
    && for arch in ${VENDOR_ARCHES}; do \
    dst="/cpaas/vendor/helm/${arch}" ; \
    test -x "${dst}/helm" \
    || { echo "missing binary: ${arch}/helm" >&2; exit 1; } ; \
    test -s "${dst}/LICENSE" \
    || { echo "missing license: ${arch}/LICENSE" >&2; exit 1; } ; \
    magic="$(od -An -tx1 -N4 "${dst}/helm" | tr -d ' \n')" ; \
    test "${magic}" = "7f454c46" \
    || { echo "not an ELF binary: ${arch}/helm (magic=${magic})" >&2; exit 1; } ; \
    case "${arch}" in \
    amd64) want="3e00" ;; \
    arm64) want="b700" ;; \
    *) echo "unsupported arch: ${arch} (only amd64 / arm64)" >&2; exit 1 ;; \
    esac ; \
    machine="$(od -An -tx1 -j18 -N2 "${dst}/helm" | tr -d ' \n')" ; \
    test "${machine}" = "${want}" \
    || { echo "ELF arch mismatch: ${arch}/helm (e_machine=${machine}, want=${want})" >&2; exit 1; } ; \
    for f in helm LICENSE; do \
    test -s "${dst}/${f}.sha256sum" \
    || { echo "missing checksum: ${arch}/${f}.sha256sum" >&2; exit 1; } ; \
    done ; \
    ( cd "${dst}" && sha256sum --check --strict ./*.sha256sum ) ; \
    done

# ---------------------------------------------------------------------------
# target
# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE}

ARG TARGETARCH

# helm
# https://github.com/helm/helm/releases
ARG INST_HELM_V=v4.3.2

ENV INST_HELM_V=${INST_HELM_V}

COPY --from=binaries /cpaas/vendor/helm/${TARGETARCH}/ /cpaas/vendor/helm/

LABEL \
    org.opencontainers.image.title="kluster-vendor-helm" \
    org.opencontainers.image.description="Upstream helm binaries repackaged as OCI artifacts" \
    org.opencontainers.image.version="${INST_HELM_V}" \
    org.opencontainers.image.source="https://github.com/cpaas-dev/kluster-vendor-helm" \
    org.opencontainers.image.vendor="Kluster" \
    org.opencontainers.image.licenses="Apache-2.0"
