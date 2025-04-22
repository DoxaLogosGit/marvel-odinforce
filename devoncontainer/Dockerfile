FROM mcr.microsoft.com/devcontainers/cpp:dev-ubuntu24.04
ENV PATH $PATH:/Odin
# Install the xz-utils package
RUN apt-get update && apt-get install -y xz-utils
RUN git clone https://github.com/odin-lang/Odin && cd Odin && git checkout dev-2025-04 && \
    make release-native && pwd