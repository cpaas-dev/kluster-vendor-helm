# kluster-vendor-helm

把上游 helm 的二进制重新打包成一个多架构 OCI 镜像，用于离线 / 内网环境分发。

[![Release](https://github.com/cpaas-dev/kluster-vendor-helm/actions/workflows/release.yml/badge.svg)](https://github.com/cpaas-dev/kluster-vendor-helm/actions/workflows/release.yml)
[![Scan upstream](https://github.com/cpaas-dev/kluster-vendor-helm/actions/workflows/scan-upstream.yml/badge.svg)](https://github.com/cpaas-dev/kluster-vendor-helm/actions/workflows/scan-upstream.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%20%7C%20linux%2Farm64-informational)

```bash
docker pull ghcr.io/cpaas-dev/kluster-vendor-helm:v4.3.2
```

## 这是什么

离线部署时需要 helm 的官方发布件。本仓库把它按目标架构解包进镜像，构建时用上游
`.sha256sum` 校验，只装二进制，不带 chart、不带仓库配置。

helm 的二进制不在 GitHub Release 资产里（那边只有 `.asc` 签名），实际发布在
<https://get.helm.sh>，所以下载走 `get.helm.sh`，版本发现走 GitHub Release。

## 镜像内容

```plain
/cpaas/vendor/helm/
├── helm                                     # 目标架构
├── helm.sha256sum
├── LICENSE                                  # 上游 Apache-2.0 许可
├── LICENSE.sha256sum
└── helm-<ver>-linux-<arch>.tar.gz.sha256    # 上游校验和，留作凭证
```

下游校验：

```bash
cd /cpaas/vendor/helm

# 单个
sha256sum -c helm.sha256sum

# 全部
sha256sum -c *.sha256sum
```

说明：

- 二进制取自上游 `helm-<ver>-linux-<arch>.tar.gz` 里的 `linux-<arch>/`，原样落盘
- 构建时逐个架构比对上游 `.sha256sum`，校验不过直接失败
- 构建期还会检查落盘文件确实是对应架构的 ELF（magic + `e_machine`）
- 每个文件额外生成一份 `<file>.sha256sum`，记的是不带路径的文件名，
  所以在该目录下 `sha256sum -c` 直接可用
- 上游 tarball 的校验和存成 `.sha256` 而不是 `.sha256sum`，避免 `*.sha256sum`
  把它也匹配进去——那个 tarball 并不在镜像里，一并校验必然失败
- 只含目标架构。`linux/arm64` 的镜像里只有 arm64 的 helm
- 上游包里的 `README.md` 不落盘，`LICENSE` 保留（重新分发 Apache-2.0 产物需要随附）
- helm v3 / v4 两条线都跟，tag 与上游版本号一致

## 文档

- [自定义构建](docs/BUILD_YOUR_OWN.md) —— build-args、下载加速
- [发布流程](docs/RELEASE.md) —— tag 规则、定时扫描、本地调试脚本
- [贡献指南](docs/CONTRIBUTING.md)

## 相关仓库

- Helm <https://github.com/helm/helm>

## 许可

本仓库的构建脚本以 Apache-2.0 发布。打包进镜像的上游产物遵循其原始许可：
Helm（Apache-2.0）。
