# One-shot container that deploys the registry contracts and exports the las2peer registry config.
FROM node:16-bullseye-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
CMD ["./scripts/deploy.sh"]
