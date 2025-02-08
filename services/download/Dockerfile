FROM debian:bullseye-slim

# Install necessary packages
RUN apt-get update && apt-get install -y \
    git \
    parallel \
    aria2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy the script and other necessary files
COPY . /docker

# Make the script executable
RUN chmod +x /docker/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/docker/entrypoint.sh"]
