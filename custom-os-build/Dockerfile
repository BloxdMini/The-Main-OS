FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-utils \
    cpio \
    genisoimage \
    mtools \
    dosfstools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    debootstrap \
    rsync \
    wget \
    curl \
    git \
    build-essential \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY scripts/ /build/scripts/
COPY assets/ /build/assets/

RUN chmod +x /build/scripts/*.sh

ENTRYPOINT ["/build/scripts/build-live-iso.sh"]
