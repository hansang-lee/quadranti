FROM debian:11-slim AS builder

ARG USERNAME="admin"
ARG UID="1000"
ARG GID="1000"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --fix-missing --no-install-recommends sudo \
 && groupadd --gid ${GID} ${USERNAME} \
 && useradd --uid ${UID} --gid ${GID} -m ${USERNAME} \
 && usermod -a -G video ${USERNAME} \
 && usermod -a -G dialout ${USERNAME} \
 && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}

# flutter
ENV PATH="${PATH}:/opt/flutter/bin"
ARG FLUTTER_VERSION="3.22.0"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --fix-missing --no-install-recommends tar wget unzip zip xz-utils openjdk-17-jdk git sudo \
 && URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && wget -qO- --no-check-certificate "${URL}" | tar --extract --xz --directory="/opt" \
 && flutter precache

# android-sdk
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/bin:${ANDROID_SDK_ROOT}/platform-tools"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --fix-missing --no-install-recommends wget libarchive-tools \
 && mkdir --parents ${ANDROID_SDK_ROOT} \
 && URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
 && wget -qO- --no-check-certificate "${URL}" | bsdtar --extract --file - --directory=${ANDROID_SDK_ROOT} \
 && chmod +x ${ANDROID_SDK_ROOT}/cmdline-tools/bin/* \
 && yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
 && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# grant user ownership of android-sdk and configure flutter
RUN chown -R ${USERNAME}:${USERNAME} /opt/flutter ${ANDROID_SDK_ROOT} \
 && flutter config --android-sdk ${ANDROID_SDK_ROOT} \
 && flutter config --no-analytics
