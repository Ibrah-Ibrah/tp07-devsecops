FROM ubuntu:22.04
# hadolint ignore=DL3008
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
