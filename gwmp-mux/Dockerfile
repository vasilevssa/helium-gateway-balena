FROM rust:1.75-bookworm as builder

WORKDIR /usr/src/app

# Clone the gwmp-mux repository
RUN git clone https://github.com/helium/gwmp-mux.git .

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary from builder stage
COPY --from=builder /usr/src/app/target/release/gwmp-mux /usr/local/bin/gwmp-mux

# Create config directory
RUN mkdir -p /etc/gwmp-mux

# Copy startup script and config template
COPY start-gwmp-mux.sh /opt/start-gwmp-mux.sh
RUN chmod +x /opt/start-gwmp-mux.sh

# Expose the GWMP port (where packet forwarder connects)
EXPOSE 1700/udp

WORKDIR /opt

ENTRYPOINT ["/opt/start-gwmp-mux.sh"]
