############################################################
# Build base
############################################################
FROM node:22-bookworm AS base

WORKDIR /usr/local/app


############################################################
# CLIENT
############################################################

FROM base AS client-base

COPY client/package.json client/package-lock.json ./
COPY .npmrc ./

RUN npm ci

COPY client/.eslintrc.cjs client/index.html client/vite.config.js ./
COPY client/public ./public
COPY client/src ./src


FROM client-base AS client-dev

CMD ["npm", "run", "dev"]


FROM client-base AS client-build

RUN npm run build


############################################################
# SQLITE NATIVE MODULE BUILD
############################################################

FROM base AS sqlite3-build

COPY backend/package.json backend/package-lock.json ./
COPY .npmrc ./

RUN npm ci

RUN cd node_modules/sqlite3 && ../.bin/node-gyp rebuild


############################################################
# BACKEND DEVELOPMENT
############################################################

FROM base AS backend-dev

COPY backend/package.json backend/package-lock.json ./
COPY .npmrc ./

RUN npm ci

COPY --from=sqlite3-build \
    /usr/local/app/node_modules/sqlite3/build \
    ./node_modules/sqlite3/build

COPY backend/spec ./spec
COPY backend/src ./src

CMD ["npm", "run", "dev"]


############################################################
# TEST
############################################################

FROM backend-dev AS test

RUN npm run test


############################################################
# PRODUCTION
############################################################

FROM node:22-bookworm-slim AS final

ENV NODE_ENV=production

WORKDIR /usr/local/app

# Production dependency manifests
COPY --from=test /usr/local/app/package.json .
COPY --from=test /usr/local/app/package-lock.json .
COPY .npmrc .

# Install production dependencies only
RUN npm ci --omit=dev \
    && npm cache clean --force \
    && rm -f .npmrc \
    && rm -rf /usr/local/lib/node_modules/npm \
              /usr/local/bin/npm \
              /usr/local/bin/npx

# Copy the native sqlite3 build
COPY --from=sqlite3-build \
    /usr/local/app/node_modules/sqlite3/build \
    ./node_modules/sqlite3/build

# Copy backend application
COPY backend/src ./src

# Copy compiled frontend into backend static directory
COPY --from=client-build \
    /usr/local/app/dist \
    ./src/static

# Use the non-root user already provided by the official Node image
USER node

EXPOSE 3000

# Existing application endpoint used as container health check
HEALTHCHECK --interval=30s \
    --timeout=5s \
    --start-period=20s \
    --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:3000/api/greeting',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/index.js"]
