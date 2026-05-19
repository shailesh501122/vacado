FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:20-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY migrations ./migrations
COPY src ./src

# Create uploads directory and ensure the node user can write to it.
# In production, mount a named volume at /app/uploads so files survive restarts.
RUN mkdir -p /app/uploads/products && chown -R node:node /app/uploads

EXPOSE 4000
USER node
CMD ["node", "src/server.js"]
