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
RUN useradd --system --uid 1001 leera
COPY --from=build /src/target/leera-backend-*.jar app.jar
USER leera
# Fits a small instance (512 MB on Render's free plan).
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+UseSerialGC -XX:TieredStopAtLevel=1"
EXPOSE 8080
# ANTHROPIC_API_KEY, LEERA_SESSION_SECRET and LEERA_DATABASE_* are needed at run time.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
