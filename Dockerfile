# Stage 1: Build the .NET application
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy everything from the host machine into the container
RUN git clone https://github.com/Walzen-Group/Readarr.git /app

# Restore dependencies
RUN dotnet clean src/Readarr.sln -c Debug

# Build and publish the app
RUN dotnet msbuild -restore src/Readarr.sln -p:Configuration=Release -p:Platform=Posix -t:PublishAllRids

FROM node:20 AS ui-build
RUN corepack enable && corepack prepare yarn@stable --activate
WORKDIR /app
COPY --from=build /app /app
RUN yarn install && yarn build

# Stage 2: Create a new runtime container
# FROM mcr.microsoft.com/dotnet/runtime:6.0 AS runtime
FROM debian:bullseye-slim AS runtime

RUN apt-get update && apt-get install -y bash libsqlite3-0 libicu-dev libssl-dev ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the published output from the build stage
COPY --from=build /app/_output/net6.0/linux-x64/ /app
# COPY --from=build /app/_output/Readarr.Update/ /app/Readarr.Update
COPY --from=ui-build /app/_output/UI/ /app/UI

ENTRYPOINT ["/app/Readarr"]
