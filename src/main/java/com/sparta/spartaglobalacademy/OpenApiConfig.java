package com.sparta.spartaglobalacademy;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        String buildNumber = System.getenv("BUILD_NUMBER"); // Jenkins sets this automatically
        if (buildNumber == null) {
            buildNumber = "local";
        }

        return new OpenAPI()
                .info(new Info()
                        .title("Sparta Global Academy API")
                        .version("v0.0.1 - Build #" + buildNumber) // <-- visible in Swagger UI
                        .description("API documentation for Sparta Global Academy"));
    }
}

