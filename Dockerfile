FROM elixir:1.11-alpine AS build

RUN apk add --update --no-cache \
    build-base \
    nodejs \
    npm \
    git

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get && \
    mix deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm install --prefix=assets

COPY lib lib
COPY rel rel
COPY priv priv
COPY assets assets

RUN npm run deploy --prefix=assets
RUN mix phx.digest
RUN mix release

FROM alpine:3.17 AS app

RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++ \
    libgcc \
    libcrypto1.1 \
    libssl1.1

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/zcash_explorer ./

ENV HOME=/app

CMD ["bin/zcash_explorer", "start"]

