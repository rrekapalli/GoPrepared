# syntax=docker/dockerfile:1

FROM docker.io/library/eclipse-temurin:21-jdk-jammy AS build
WORKDIR /workspace
COPY mvnw pom.xml ./
COPY .mvn .mvn
RUN chmod +x mvnw
COPY src src
RUN ./mvnw -q -DskipTests package

FROM docker.io/library/eclipse-temurin:21-jre-jammy
WORKDIR /app
RUN useradd --system --uid 10001 --home /app goprepared \
    && apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /workspace/target/go-prepared-api-*.jar /app/app.jar
RUN chown goprepared:goprepared /app/app.jar
USER goprepared
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -sf http://127.0.0.1:8080/api/v1/knowledge/categories >/dev/null || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
