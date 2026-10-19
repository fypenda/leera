# Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B package -DskipTests

# Run
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --system --uid 1001 nourish
COPY --from=build /src/target/nourish-backend-*.jar app.jar
USER nourish
EXPOSE 8080
# NOURISH_APP_TOKEN and ANTHROPIC_API_KEY are required at run time.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
