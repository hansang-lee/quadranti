# Optional dev container: Flutter + Android SDK. Not needed when Flutter is
# installed locally (see docs/development.md).
FROM debian:12-slim

ARG USERNAME="admin"
ARG UID="1000"
ARG GID="1000"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip libarchive-tools openjdk-17-jdk-headless \
 && groupadd --gid ${GID} ${USERNAME} \
 && useradd --uid ${UID} --gid ${GID} -m ${USERNAME}

# flutter (keep in step with .github/workflows/ci.yml)
ENV PATH="${PATH}:/opt/flutter/bin"
ARG FLUTTER_VERSION="3.47.5"
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar --extract --xz --directory=/opt \
 && git config --system --add safe.directory /opt/flutter

# android-sdk
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/bin:${ANDROID_SDK_ROOT}/platform-tools"
RUN mkdir --parents ${ANDROID_SDK_ROOT} \
 && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
      | bsdtar --extract --file - --directory=${ANDROID_SDK_ROOT} \
 && chmod +x ${ANDROID_SDK_ROOT}/cmdline-tools/bin/* \
 && yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses > /dev/null \
 && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-36" "build-tools;36.0.0"

RUN chown -R ${USERNAME}:${USERNAME} /opt/flutter ${ANDROID_SDK_ROOT}
USER ${USERNAME}
RUN flutter config --android-sdk ${ANDROID_SDK_ROOT} \
 && flutter config --no-analytics \
 && flutter precache --web --android
