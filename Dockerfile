# One-shot container that deploys the registry contracts and exports the las2peer registry config.
FROM ghcr.io/foundry-rs/foundry:v1.8.5
USER root
WORKDIR /app
COPY . .
RUN forge install --no-git foundry-rs/forge-std@v1.17.0 && forge build
CMD ["./scripts/deploy.sh"]
