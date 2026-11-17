## 打包

```bash
# 构建多架构镜像 amd64/arm64
docker buildx build --platform linux/amd64,linux/arm64 \
  -t xxx .
```

## 指定版本

```bash
docker buildx build \
  --build-arg INST_HELM_V=v4.3.2 \
  -t ...
```

## 下载加速

helm 的二进制发布在 `get.helm.sh`（Google 存储），不在 GitHub Release 上，
所以这里换的是 `HELM_URL` 而不是 `GITHUB_URL`。

```bash
# 国内访问加速，DaoCloud 的 get.helm.sh 镜像，路径与上游一一对应
docker buildx build \
  --build-arg HELM_URL=https://files.m.daocloud.io/get.helm.sh \
  -t ...
```

华为云也有 helm 的镜像，但路径是 `https://mirrors.huaweicloud.com/helm/<ver>/<file>`，
多了一层版本目录，套不进 `HELM_URL` 这种单一前缀；而且只跟到 v3，没有 v4。要用的话
得自己在 Nexus 之类的地方做一层 raw proxy，把路径改写成 `get.helm.sh` 的形状。

不管走哪个源，构建时都会拿同源的 `.sha256sum` 校验，镜像内容与直连上游一致。

## 其他 build-args

```bash
# 基础镜像
BASE_IMAGE=docker.io/rockylinux/rockylinux:10.2.20260525.0

# 下载哪些架构的二进制，空格分隔。
# 最终镜像只装 TARGETARCH，这里改小只能省下载量，改小于目标架构集合会构建失败
VENDOR_ARCHES="amd64 arm64"
```
