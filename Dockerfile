FROM rust:1.52 as planner
WORKDIR app
RUN cargo install cargo-chef
COPY Cargo.toml Cargo.lock ./
COPY src src
RUN cargo chef prepare  --recipe-path recipe.json

FROM rust:1.52 as cacher
WORKDIR app
RUN cargo install cargo-chef
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust:1.52 as builder
WORKDIR app
COPY Cargo.toml Cargo.lock ./
COPY src src
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release

FROM rust:1.52 as runtime
COPY --from=builder /app/target/release/websocket-server /usr/local/bin/app
EXPOSE 8000
CMD ["app"]