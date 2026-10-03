---
name: create-microservice
description: Cria microservicos Java/Spring Boot do zero seguindo a arquitetura padrao da organizacao (Layered Architecture, Facade, Proxy/Gateway, WebClient, Oracle DB, K8s/Kustomize, Basic Auth, auditoria em BD). Suporta tipos Proxy/Gateway, CRUD, Event-Driven e Hibrido. Aceita PRD.md como entrada ou gera um interativamente.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: scaffolding
  stack: java-spring-boot
---

# Skill: Criar Microservico Java/Spring Boot

## Proposito

Esta skill automatiza a criacao completa de microservicos Java/Spring Boot seguindo os padroes arquiteturais da organizacao SPC Brasil / Negociar Divida. Ela gera TODA a estrutura do projeto do zero, incluindo codigo Java, configuracoes, manifests K8s e CI/CD.

---

## Fluxo de Interacao

### 1. Verificar se usuario forneceu PRD

- Se o usuario referenciou um arquivo PRD.md (ou similar), leia-o e extraia os parametros
- Se NAO forneceu, faca as **perguntas-chave** abaixo para coletar os parametros
- Se o usuario pedir para GERAR um PRD, crie o arquivo `tap/PRD.md` (ou path solicitado) com os parametros coletados antes de implementar

### 2. Perguntas-Chave (fazer ao usuario se nao houver PRD)

Faca TODAS estas perguntas de uma vez (use a ferramenta question com multiplas perguntas):

**Bloco 1 - Identificacao:**
- Qual o nome do projeto? (ex: `negociar-dividas-serasa`)
- Qual a descricao? (ex: `API de integracao com Serasa`)
- Qual o context-path? (ex: `/externo/serasa`)
- Qual o groupId Maven? (default: `br.org.spcbrasil`)
- Qual o base package? (default derivado do nome)

**Bloco 2 - Tipo de Microservico:**
- Proxy/Gateway (intermedia API externa)
- CRUD (dominio proprio com persistencia)
- Event-Driven (Kafka/RabbitMQ)
- Hibrido (combinacao)

**Bloco 3 - Integracao Externa (se Proxy/Gateway ou Hibrido):**
- Nome da integracao (ex: `ativos`, `serasa`)
- URL base por ambiente (DEV, STG, PRD)
- Tipo de autenticacao (Bearer Token, API Key, OAuth2, nenhuma)
- Endpoint de login (se Bearer Token)
- TTL do token em minutos (default: 55)

**Bloco 4 - Dominios e Endpoints:**
- Quais dominios/entidades? (ex: cliente, operacao, acordo)
- Para cada dominio, quais endpoints? (metodo, path, params, response)

**Bloco 5 - Banco de Dados:**
- Tipo (Oracle/PostgreSQL/MySQL)
- Hosts por ambiente
- Usar auditoria/logging em BD? (sim/nao)
- Tabelas de log necessarias
- Usar Liquibase? (sim/nao)

**Bloco 6 - Eventos (se Event-Driven ou Hibrido):**
- Broker (Kafka/RabbitMQ)
- Topics para consumir
- Topics para produzir
- Consumer group

**Bloco 7 - Infraestrutura:**
- Namespace K8s
- Nome do deployment
- Registry da imagem Docker
- Recursos (CPU/Memory) ou usar defaults

### 3. Apos coletar parametros, implementar seguindo o Cookbook abaixo

---

## Stack Obrigatoria

| Componente | Versao/Tecnologia |
|-----------|-------------------|
| Java | 17 |
| Spring Boot | 3.3.4 |
| Build | Maven (wrapper) |
| DB Driver | Oracle OJDBC11 / PostgreSQL |
| Security | Spring Security (Basic Auth, stateless) |
| HTTP Client | WebClient (Spring WebFlux) |
| Docs | SpringDoc OpenAPI 2.5.0 |
| Boilerplate | Lombok |
| Mapping | ModelMapper 3.2.0 |
| Secrets | spring-boot-secrets 2.0.0 (SPC interno) |
| Container | Kubernetes + Kustomize |
| CI/CD | GitLab CI |

---

## Design Patterns Obrigatorios

| Pattern | Aplicacao |
|---------|-----------|
| **Layered Architecture** | API Layer -> Domain Layer -> Integration Layer |
| **Facade** | Service orquestrador unico ponto de entrada para controller |
| **Interface + Impl** | Todos services e clients |
| **Wrapper Response** | `{Integracao}ClientResponse<T>` para chamadas externas |
| **DTO por camada** | DTOs de API != DTOs de integracao != Entities |
| **Builder** | `@Builder` / `@SuperBuilder` em entities e responses |
| **Repository** | Spring Data JPA |
| **Filter (ExchangeFilterFunction)** | Injecao automatica de Bearer Token |
| **Template Method** | `BaseLogEntity` + subclasses |
| **Enum i18n** | Enum `Mensagem` + `messages.properties` |

---

## Convencoes de Nomenclatura

| Elemento | Padrao |
|----------|--------|
| Pacote | lowercase, singular (`acordo`, `boleto`) |
| Controller | `{Dominio}Controller` |
| Service Interface | `{Dominio}Service` ou `{Dominio}{Integracao}Service` |
| Service Impl | `{Dominio}{Integracao}ServiceImpl` |
| Client Interface | `{Dominio}{Integracao}Client` |
| Client Impl | `{Dominio}{Integracao}ClientImpl` |
| DTO | `{Acao}{Dominio}DTO` ou `{Acao}{Dominio}RequestDTO` / `{Acao}{Dominio}ResponseDTO` |
| Log Entity | `{Acao}{Dominio}LogEntity` |
| Log Repository | `{Acao}{Dominio}LogRepository` |
| Tabela log | `{ABREV_ACAO}_{ABREV_DOMINIO}_LOG` |
| Sequence | `SQ_{TABELA}` |
| Properties class | `{Integracao}Property` |
| Constantes | `Constantes{Integracao}` com sub-interfaces |

---

## Regras de Codigo

1. **DI por construtor** - `@RequiredArgsConstructor` sempre; nunca `@Autowired` em campo
2. **Sem logica no controller** - Controller apenas delega para service
3. **Try-catch apenas no client** - Services nao capturam excecoes de client
4. **Null-safe** - `ObjectUtils.isEmpty()` ou `Optional`
5. **Jackson strict mode** - `fail-on-unknown-properties=true`, `fail-on-ignored-properties=true`
6. **Logs com @Slf4j** - ERROR para excecoes, INFO para fluxo, DEBUG para detalhe
7. **Constantes centralizadas** - Nunca strings magicas no codigo
8. **Heranca apenas em Entities** - DTOs sao flat com composicao

---

## Cookbook de Implementacao

Apos coletar os parametros, execute TODOS os passos abaixo em sequencia. Use a ferramenta TodoWrite para acompanhar o progresso.

### PASSO 1: Criar estrutura de diretorios

```
{project-root}/
├── .gitlab-ci.yml
├── build.sh
├── Dockerfile
├── pom.xml
├── .mvn/wrapper/
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── development/kustomization.yaml
│       ├── staging/kustomization.yaml
│       └── production/kustomization.yaml
└── src/
    ├── main/
    │   ├── java/{base_package_path}/
    │   │   ├── {App}Application.java
    │   │   ├── api/controller/v1/
    │   │   │   ├── {Dominio}Controller.java
    │   │   │   ├── {dominio}/ (DTOs)
    │   │   │   └── controlleradvice/
    │   │   ├── {integracao}/ (se proxy)
    │   │   │   ├── Authorization{Integracao}.java
    │   │   │   ├── Constantes{Integracao}.java
    │   │   │   ├── client/
    │   │   │   └── config/
    │   │   ├── config/
    │   │   │   ├── SecurityConfig.java
    │   │   │   ├── OpenApiConfig.java
    │   │   │   ├── MessageConfiguration.java
    │   │   │   └── security/
    │   │   └── domain/
    │   │       ├── entity/ (se CRUD)
    │   │       ├── repository/ (se CRUD)
    │   │       ├── jackson/
    │   │       ├── log/entity/
    │   │       ├── log/repository/
    │   │       ├── service/
    │   │       ├── service/impl/
    │   │       ├── exception/
    │   │       ├── utils/
    │   │       └── validator/
    │   └── resources/
    │       ├── application.properties
    │       ├── application-LCL.properties
    │       ├── application-DEV.properties
    │       ├── application-STG.properties
    │       ├── application-PRD.properties
    │       └── messages.properties
    ├── test/java/{base_package_path}/
    └── integration-test/java/{base_package_path}/
```

### PASSO 2: Gerar pom.xml

Usar o template abaixo substituindo parametros:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
        <relativePath/>
    </parent>
    <groupId>{GROUP_ID}</groupId>
    <artifactId>{ARTIFACT_ID}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>{PROJECT_NAME}</name>
    <description>{PROJECT_DESCRIPTION}</description>
    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <!-- spring-boot-secrets (SPC interno) -->
        <dependency>
            <groupId>br.org.spcbrasil.springboot</groupId>
            <artifactId>spring-boot-secrets</artifactId>
            <version>2.0.0</version>
        </dependency>
        <!-- Core -->
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
        <!-- WebClient (se Proxy/Gateway) -->
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-webflux</artifactId></dependency>
        <!-- Kafka (se Event-Driven) - descomentar se necessario -->
        <!--<dependency><groupId>org.springframework.kafka</groupId><artifactId>spring-kafka</artifactId></dependency>-->
        <!-- Documentacao -->
        <dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.5.0</version></dependency>
        <!-- Database -->
        <dependency><groupId>com.oracle.database.jdbc</groupId><artifactId>ojdbc11</artifactId><scope>runtime</scope></dependency>
        <!-- Utilitarios -->
        <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
        <dependency><groupId>org.modelmapper</groupId><artifactId>modelmapper</artifactId><version>3.2.0</version></dependency>
        <dependency><groupId>org.apache.commons</groupId><artifactId>commons-lang3</artifactId></dependency>
        <dependency><groupId>com.fasterxml.jackson.datatype</groupId><artifactId>jackson-datatype-jsr310</artifactId></dependency>
        <!-- Test -->
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
        <dependency><groupId>com.h2database</groupId><artifactId>h2</artifactId><scope>test</scope></dependency>
        <dependency><groupId>org.liquibase</groupId><artifactId>liquibase-core</artifactId><scope>test</scope></dependency>
    </dependencies>
    <repositories>
        <repository><id>central</id><url>https://gitlab.spcdc.org.br/api/v4/projects/2041/packages/maven</url></repository>
        <repository><id>maven_central</id><name>Maven Central</name><url>https://repo.maven.apache.org/maven2/</url></repository>
    </repositories>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes><exclude><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId></exclude></excludes>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>build-helper-maven-plugin</artifactId>
                <version>3.4.0</version>
                <executions>
                    <execution>
                        <id>add-integration-test-source</id>
                        <phase>generate-test-sources</phase>
                        <goals><goal>add-test-source</goal></goals>
                        <configuration><sources><source>src/integration-test/java</source></sources></configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.2</version>
                <configuration><excludes><exclude>**/*IT</exclude></excludes></configuration>
            </plugin>
        </plugins>
    </build>
    <profiles>
        <profile>
            <id>integration-test</id>
            <build>
                <plugins>
                    <plugin>
                        <artifactId>maven-surefire-plugin</artifactId>
                        <executions>
                            <execution>
                                <phase>integration-test</phase>
                                <goals><goal>test</goal></goals>
                                <configuration>
                                    <excludes><exclude>none</exclude></excludes>
                                    <includes><include>**/*IT</include></includes>
                                </configuration>
                            </execution>
                        </executions>
                    </plugin>
                </plugins>
            </build>
        </profile>
    </profiles>
</project>
```

### PASSO 3: Gerar Application.java

```java
package {BASE_PACKAGE};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class {AppName}Application {
    public static void main(String[] args) {
        SpringApplication.run({AppName}Application.class, args);
    }
}
```

### PASSO 4: Gerar application.properties (todos profiles)

**Base:**
```properties
server.servlet.context-path={CONTEXT_PATH}
server.port=8080
spring.jackson.deserialization.fail-on-unknown-properties=true
spring.jackson.deserialization.fail-on-ignored-properties=true
spring.jpa.hibernate.ddl-auto=none
spring.jpa.show-sql=false
spring.jpa.open-in-view=false
spring.security.user.name=${SECURITY_USER:admin}
spring.security.user.password=${SECURITY_PASSWORD:admin}
{integracao}.username=${INTEGRACAO_USERNAME}
{integracao}.password=${INTEGRACAO_PASSWORD}
{integracao}.base-url=${INTEGRACAO_BASE_URL}
management.endpoints.web.exposure.include=health,info,metrics
springdoc.api-docs.path=/v3/api-docs
springdoc.swagger-ui.path=/swagger-ui.html
```

**Por ambiente (LCL, DEV, STG, PRD):** configurar datasource URL, integracao base-url, logging levels. Em ambientes nao-locais usar `oracle-decrypt()` para senha.

### PASSO 5: Gerar SecurityConfig.java

```java
package {BASE_PACKAGE}.config;

import {BASE_PACKAGE}.config.security.{Nome}AuthenticationEntryPoint;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final {Nome}AuthenticationEntryPoint authenticationEntryPoint;

    private static final String[] AUTH_WHITELIST = {
        "/v3/api-docs/**", "/swagger-ui.html", "/swagger-ui/**",
        "/actuator/**", "/h2-console/**"
    };

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(AUTH_WHITELIST).permitAll()
                .anyRequest().authenticated());
        http.sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.csrf(AbstractHttpConfigurer::disable);
        http.httpBasic(b -> b.authenticationEntryPoint(authenticationEntryPoint));
        return http.build();
    }
}
```

### PASSO 6: Gerar AuthenticationEntryPoint

```java
package {BASE_PACKAGE}.config.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import java.io.IOException;

@Component
public class {Nome}AuthenticationEntryPoint implements AuthenticationEntryPoint {
    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write("{\"status\":401,\"titulo\":\"Nao autorizado\",\"detalhe\":\"Credenciais invalidas\"}");
    }
}
```

### PASSO 7: Gerar Exception Handling

Criar TODOS estes arquivos:
- `domain/exception/Mensagem.java` (enum com chaves de negocio)
- `domain/exception/NegocioException.java`
- `domain/exception/InfraestruturaException.java`
- `domain/exception/ListaNegocioException.java`
- `api/controller/v1/controlleradvice/Problema.java`
- `api/controller/v1/controlleradvice/TipoProblema.java`
- `api/controller/v1/controlleradvice/ApiExceptionHandler.java`

**Mensagem.java:**
```java
package {BASE_PACKAGE}.domain.exception;

public enum Mensagem {
    ERRO_500,
    PARAMETRO_OBRIGATORIO,
    RECURSO_NAO_ENCONTRADO,
    ERRO_INTEGRACAO_EXTERNA;
    // Adicionar mensagens especificas do dominio
}
```

**NegocioException.java:**
```java
package {BASE_PACKAGE}.domain.exception;

import lombok.Getter;

@Getter
public class NegocioException extends RuntimeException {
    private final Mensagem mensagem;
    private final transient Object[] parametros;

    public NegocioException(Mensagem mensagem) {
        this.mensagem = mensagem;
        this.parametros = null;
    }

    public NegocioException(Mensagem mensagem, Object... parametros) {
        this.mensagem = mensagem;
        this.parametros = parametros;
    }

    public String getMensagem() { return mensagem.toString(); }
}
```

**InfraestruturaException.java:**
```java
package {BASE_PACKAGE}.domain.exception;

import lombok.Getter;

@Getter
public class InfraestruturaException extends RuntimeException {
    private final Mensagem mensagem;
    private final transient Object[] parametros;

    public InfraestruturaException(Mensagem mensagem) {
        this.mensagem = mensagem;
        this.parametros = null;
    }

    public InfraestruturaException(Mensagem mensagem, Object... parametros) {
        this.mensagem = mensagem;
        this.parametros = parametros;
    }
}
```

**Problema.java:**
```java
package {BASE_PACKAGE}.api.controller.v1.controlleradvice;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
@Getter @Setter @Builder
public class Problema {
    private Integer status;
    private String titulo;
    private String detalhe;
    private String chave;
    private String timestamp;
    private List<Field> campos;

    @Getter @AllArgsConstructor
    public static class Field {
        private String nome;
        private String mensagem;
    }
}
```

**TipoProblema.java:**
```java
package {BASE_PACKAGE}.api.controller.v1.controlleradvice;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum TipoProblema {
    ERRO_NEGOCIO("Erro de negocio", HttpStatus.BAD_REQUEST),
    ERRO_SISTEMA("Erro interno", HttpStatus.INTERNAL_SERVER_ERROR),
    RECURSO_NAO_ENCONTRADO("Recurso nao encontrado", HttpStatus.NOT_FOUND);

    private final String titulo;
    private final HttpStatus status;

    TipoProblema(String titulo, HttpStatus status) {
        this.titulo = titulo;
        this.status = status;
    }
}
```

**ApiExceptionHandler.java:**
```java
package {BASE_PACKAGE}.api.controller.v1.controlleradvice;

import {BASE_PACKAGE}.domain.exception.*;
import {BASE_PACKAGE}.domain.utils.MensagemUtils;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import java.time.Instant;

@ControllerAdvice @Slf4j @AllArgsConstructor
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    private final MensagemUtils mensagemUtils;

    @ExceptionHandler(NegocioException.class)
    public ResponseEntity<Object> handleNegocio(NegocioException ex, WebRequest request) {
        TipoProblema tipo = TipoProblema.ERRO_NEGOCIO;
        Problema problema = Problema.builder()
            .status(tipo.getStatus().value())
            .titulo(tipo.getTitulo())
            .chave(ex.getMensagem())
            .detalhe(mensagemUtils.getMensagemString(ex.getMensagem(), ex.getParametros()))
            .timestamp(Instant.now().toString())
            .build();
        return handleExceptionInternal(ex, problema, new HttpHeaders(), tipo.getStatus(), request);
    }

    @ExceptionHandler(InfraestruturaException.class)
    public ResponseEntity<Object> handleInfra(InfraestruturaException ex, WebRequest request) {
        log.error("Erro infraestrutura", ex);
        TipoProblema tipo = TipoProblema.ERRO_SISTEMA;
        Problema problema = Problema.builder()
            .status(tipo.getStatus().value())
            .titulo(tipo.getTitulo())
            .chave(ex.getMensagem().toString())
            .detalhe("Erro interno do servidor")
            .timestamp(Instant.now().toString())
            .build();
        return handleExceptionInternal(ex, problema, new HttpHeaders(), tipo.getStatus(), request);
    }
}
```

### PASSO 8: Gerar Utils

- `domain/utils/MensagemUtils.java`
- `domain/utils/DateUtils.java`
- `domain/utils/StringUtils.java`
- `src/main/resources/messages.properties`

**MensagemUtils.java:**
```java
package {BASE_PACKAGE}.domain.utils;

import lombok.RequiredArgsConstructor;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.stereotype.Component;

@Component @RequiredArgsConstructor
public class MensagemUtils {
    private final MessageSource messageSource;

    public String getMensagemString(String chave, Object... params) {
        return messageSource.getMessage(chave, params, chave, LocaleContextHolder.getLocale());
    }
}
```

**messages.properties:**
```properties
ERRO_500=Erro interno do servidor. Tente novamente mais tarde.
PARAMETRO_OBRIGATORIO=O parametro {0} e obrigatorio.
RECURSO_NAO_ENCONTRADO=Recurso nao encontrado.
ERRO_INTEGRACAO_EXTERNA=Erro na comunicacao com servico externo.
```

### PASSO 9: Gerar MessageConfiguration

```java
package {BASE_PACKAGE}.config;

import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;

@Configuration
public class MessageConfiguration {
    @Bean
    public MessageSource messageSource() {
        ReloadableResourceBundleMessageSource messageSource = new ReloadableResourceBundleMessageSource();
        messageSource.setBasename("classpath:messages");
        messageSource.setDefaultEncoding("UTF-8");
        return messageSource;
    }
}
```

### PASSO 10: Gerar OpenApiConfig

```java
package {BASE_PACKAGE}.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.*;
import org.springframework.context.annotation.Configuration;

@OpenAPIDefinition(info = @Info(
    contact = @Contact(name = "SPC Brasil", email = "https://spcbrasil.org.br/"),
    description = "{PROJECT_DESCRIPTION}",
    title = "{PROJECT_NAME}",
    version = "1.0"
))
@Configuration
public class OpenApiConfig {}
```

### PASSO 11: Gerar Integracao Externa (se Proxy/Gateway)

Para CADA integracao, criar:

1. `{integracao}/config/{Integracao}Property.java` - @ConfigurationProperties
2. `{integracao}/config/WebClientConfig.java` - Bean WebClient com filter
3. `{integracao}/config/WebClientBearerTokenExchangeFilterFunction.java` - Filter
4. `{integracao}/Authorization{Integracao}.java` - Cache estatico de token
5. `{integracao}/Constantes{Integracao}.java` - Paths da API externa
6. `{integracao}/client/{Integracao}ClientResponse.java` - Wrapper generico

**{Integracao}Property.java:**
```java
package {BASE_PACKAGE}.{integracao}.config;

import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.annotation.Validated;

@Configuration
@ConfigurationProperties(prefix = "{integracao}")
@Getter @Setter @Validated
public class {Integracao}Property {
    @NotEmpty private String username;
    @NotEmpty private String password;
    @NotEmpty private String baseUrl;
}
```

**WebClientConfig.java:**
```java
package {BASE_PACKAGE}.{integracao}.config;

import {BASE_PACKAGE}.{integracao}.client.login.Login{Integracao}Client;
import io.netty.handler.logging.LogLevel;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.ExchangeFilterFunction;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;
import reactor.netty.transport.logging.AdvancedByteBufFormat;

@Configuration @RequiredArgsConstructor
public class WebClientConfig {
    private final Login{Integracao}Client loginClient;
    private final {Integracao}Property property;

    @Bean
    public WebClient webClient() {
        return WebClient.builder()
            .filter(bearerTokenFilter())
            .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .baseUrl(property.getBaseUrl())
            .clientConnector(new ReactorClientHttpConnector(
                HttpClient.create().wiretap("reactor.netty.http.client.HttpClient",
                    LogLevel.DEBUG, AdvancedByteBufFormat.TEXTUAL)))
            .build();
    }

    @Bean
    public ExchangeFilterFunction bearerTokenFilter() {
        return new WebClientBearerTokenExchangeFilterFunction(loginClient, property);
    }
}
```

**WebClientBearerTokenExchangeFilterFunction.java:**
```java
package {BASE_PACKAGE}.{integracao}.config;

import {BASE_PACKAGE}.{integracao}.Authorization{Integracao};
import {BASE_PACKAGE}.{integracao}.client.{Integracao}ClientResponse;
import {BASE_PACKAGE}.{integracao}.client.login.Login{Integracao}Client;
import {BASE_PACKAGE}.{integracao}.client.login.postlogin.LoginResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.reactive.function.client.*;
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;
import static {BASE_PACKAGE}.{integracao}.Constantes{Integracao}.PATH_LOGIN_ACESSTOKEN;

@RequiredArgsConstructor
public class WebClientBearerTokenExchangeFilterFunction implements ExchangeFilterFunction {
    private final Login{Integracao}Client loginClient;
    private final {Integracao}Property property;

    @Override
    public Mono<ClientResponse> filter(ClientRequest request, ExchangeFunction next) {
        if (!request.url().getPath().contains("/login")) {
            autentica();
            request = ClientRequest.from(request)
                .header(HttpHeaders.AUTHORIZATION, Authorization{Integracao}.getAuthorization())
                .build();
        }
        return next.exchange(request);
    }

    private synchronized void autentica() {
        if (!Authorization{Integracao}.isAuthorizated()) {
            {Integracao}ClientResponse<LoginResponse> response =
                loginClient.postLogin(property.getUsername(), property.getPassword());
            if (response.getStatusCode().is2xxSuccessful() && response.getRetorno() != null) {
                Authorization{Integracao}.setAuthorization("Bearer " + response.getRetorno().getAccessToken());
                Authorization{Integracao}.setDataHora(LocalDateTime.now());
            }
        }
    }
}
```

**Authorization{Integracao}.java:**
```java
package {BASE_PACKAGE}.{integracao};

import lombok.Getter;
import lombok.Setter;
import org.springframework.util.ObjectUtils;
import java.time.LocalDateTime;
import static java.time.temporal.ChronoUnit.MINUTES;

public class Authorization{Integracao} {
    private static final int TOKEN_TTL_MINUTES = {TOKEN_TTL};
    private Authorization{Integracao}() {}

    @Getter @Setter private static String authorization;
    @Getter @Setter private static LocalDateTime dataHora;

    public static boolean isAuthorizated() {
        return !ObjectUtils.isEmpty(authorization) && isTokenValid();
    }
    private static boolean isTokenValid() {
        return dataHora != null && MINUTES.between(dataHora, LocalDateTime.now()) < TOKEN_TTL_MINUTES;
    }
}
```

**Constantes{Integracao}.java:**
```java
package {BASE_PACKAGE}.{integracao};

public interface Constantes{Integracao} {
    String PATH_LOGIN_ACESSTOKEN = "{AUTH_ENDPOINT}";

    // Sub-interfaces por dominio
    interface {DOMINIO} {
        String PATH_{DOMINIO} = "/v1/{recurso}";
        String PATH_{DOMINIO}_{PARAM} = PATH_{DOMINIO} + "/{param}";
    }
}
```

**{Integracao}ClientResponse.java:**
```java
package {BASE_PACKAGE}.{integracao}.client;

import lombok.*;
import org.springframework.http.HttpStatus;

@Builder @Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class {Integracao}ClientResponse<T> {
    private HttpStatus statusCode;
    private String retornoErro;
    private T retorno;
}
```

### PASSO 12: Gerar Login Client (se Bearer Token)

**Interface:**
```java
package {BASE_PACKAGE}.{integracao}.client.login;

import {BASE_PACKAGE}.{integracao}.client.{Integracao}ClientResponse;
import {BASE_PACKAGE}.{integracao}.client.login.postlogin.LoginResponse;

public interface Login{Integracao}Client {
    {Integracao}ClientResponse<LoginResponse> postLogin(String username, String password);
}
```

**LoginResponse.java:**
```java
package {BASE_PACKAGE}.{integracao}.client.login.postlogin;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class LoginResponse {
    @JsonProperty("access_token")
    private String accessToken;
}
```

**LoginClientImpl.java:**
```java
package {BASE_PACKAGE}.{integracao}.client.login.impl;

import {BASE_PACKAGE}.{integracao}.client.{Integracao}ClientResponse;
import {BASE_PACKAGE}.{integracao}.client.login.Login{Integracao}Client;
import {BASE_PACKAGE}.{integracao}.client.login.postlogin.LoginResponse;
import {BASE_PACKAGE}.{integracao}.config.{Integracao}Property;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import static {BASE_PACKAGE}.{integracao}.Constantes{Integracao}.PATH_LOGIN_ACESSTOKEN;

@Service @RequiredArgsConstructor @Slf4j
public class Login{Integracao}ClientImpl implements Login{Integracao}Client {
    private final {Integracao}Property property;

    @Override
    public {Integracao}ClientResponse<LoginResponse> postLogin(String username, String password) {
        WebClient webClient = WebClient.builder().baseUrl(property.getBaseUrl()).build();
        MultipartBodyBuilder builder = new MultipartBodyBuilder();
        builder.part("username", username);
        builder.part("password", password);

        {Integracao}ClientResponse<LoginResponse> retorno = new {Integracao}ClientResponse<>();
        try {
            LoginResponse loginResponse = webClient.post()
                .uri(PATH_LOGIN_ACESSTOKEN)
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(builder.build()))
                .retrieve()
                .bodyToMono(LoginResponse.class)
                .block();
            retorno.setRetorno(loginResponse);
            retorno.setStatusCode(HttpStatus.OK);
        } catch (WebClientResponseException ex) {
            retorno.setStatusCode((HttpStatus) ex.getStatusCode());
            retorno.setRetornoErro(ex.getResponseBodyAsString());
            log.error("Erro no login", ex);
        }
        return retorno;
    }
}
```

### PASSO 13: Gerar Domain Clients (para cada dominio)

Para CADA dominio da integracao, criar:
1. Interface: `{integracao}/client/{dominio}/{Dominio}{Integracao}Client.java`
2. Impl: `{integracao}/client/{dominio}/impl/{Dominio}{Integracao}ClientImpl.java`
3. DTOs: `{integracao}/client/{dominio}/{acao}/{Acao}{Dominio}DTO.java`

Seguir o padrao do `AcordoAtivosClientImpl`:
- WebClient GET/POST com `.block()`
- Try-catch `WebClientResponseException` -> preenche wrapper
- Catch generico `Exception` -> log.error

### PASSO 14: Gerar Domain Services (para cada dominio)

Para CADA dominio:
1. Interface: `domain/service/{Dominio}{Integracao}Service.java`
2. Impl: `domain/service/impl/{Dominio}{Integracao}ServiceImpl.java`

Seguir o padrao do `AcordoAtivosServiceImpl`:
- Medir tempo com `Instant.now()` + `Duration.between()`
- Chamar client
- Serializar response com ObjectMapper
- Gravar log entity
- Retornar `response.getRetorno()`

### PASSO 15: Gerar Service Orquestrador (Facade)

Se houver multiplos dominios, criar:
- `domain/service/{Nome}Service.java` (interface facade)
- `domain/service/impl/{Nome}ServiceImpl.java`

Este service:
- Injeta todos os domain services
- Faz validacoes de entrada (throw NegocioException se invalido)
- Coordena chamadas entre services
- Monta DTOs de response da API

### PASSO 16: Gerar Controller

```java
package {BASE_PACKAGE}.api.controller.v1;

import {BASE_PACKAGE}.domain.service.{Nome}Service;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor
@RequestMapping(produces = MediaType.APPLICATION_JSON_VALUE)
public class {Nome}Controller {
    private final {Nome}Service service;

    // Gerar um metodo por endpoint definido nos parametros
}
```

### PASSO 17: Gerar Log Entities (se auditoria habilitada)

Para CADA operacao que deve ser auditada:
1. Entity: `domain/log/entity/{Acao}{Dominio}LogEntity.java`
2. Repository: `domain/log/repository/{Acao}{Dominio}LogRepository.java`

Seguir padrao BaseLogEntity + @SequenceGenerator especifico.

### PASSO 18: Gerar BaseLogEntity

```java
package {BASE_PACKAGE}.domain.log.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import java.time.LocalDateTime;

@MappedSuperclass @SuperBuilder @NoArgsConstructor @Getter @Setter
public abstract class BaseLogEntity {
    @Id @Column(name = "IDFD_LOG")
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SQ_LOG")
    private Long id;

    @Column(name = "STTS_CODG") private Integer statusCode;
    @Column(name = "PRMT_RQSC") private String parametrosRequest;
    @Column(name = "RSPT_RQSC") private String response;
    @Column(name = "TMPO_EXCC") private Long tempoExecucao;
    @Column(name = "DATA_HORA_INCL", nullable = false) private LocalDateTime dataHoraInclusao;

    @PrePersist
    private void prePersist() { dataHoraInclusao = LocalDateTime.now(); }
}
```

### PASSO 19: Gerar Validator

Criar:
- `domain/validator/Validador.java`
- `domain/validator/ValidadorPadraoImp.java`
- `domain/validator/ErroDeValidacaoCampo.java`
- `domain/validator/ErroDeValidacaoCampoException.java`
- `domain/validator/ResultadoValidacaoCampo.java`

### PASSO 20: Gerar Custom Jackson Deserializer (se necessario)

Se a API externa usa formatos de data nao-padrao:
```java
package {BASE_PACKAGE}.domain.jackson;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.*;
import lombok.extern.slf4j.Slf4j;
import java.io.IOException;
import java.time.*;

@Slf4j
public class CustomLocalDateTimeDeserializer extends JsonDeserializer<LocalDateTime> {
    @Override
    public LocalDateTime deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String date = p.getText();
        try {
            return LocalDateTime.of(LocalDate.parse(date.substring(0, 10)), LocalTime.MIN);
        } catch (Exception e) {
            log.info("Formato nao reconhecido: {}", date);
        }
        throw new IOException("Formato de data invalido: " + date);
    }
}
```

### PASSO 21: Gerar CRUD Entities (se tipo CRUD ou Hibrido)

Para cada entidade de dominio:
```java
@Entity @Table(name = "{TABELA}")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class {Dominio}Entity {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SQ_{TABELA}")
    @SequenceGenerator(name = "SQ_{TABELA}", sequenceName = "SQ_{TABELA}", allocationSize = 1)
    @Column(name = "ID")
    private Long id;

    // campos...

    @Column(name = "DATA_CRIACAO", nullable = false, updatable = false)
    private LocalDateTime dataCriacao;

    @PrePersist
    private void prePersist() { dataCriacao = LocalDateTime.now(); }
}
```

### PASSO 22: Gerar Kafka (se Event-Driven ou Hibrido)

- `messaging/config/KafkaConfig.java`
- `messaging/consumer/{Evento}Consumer.java`
- `messaging/producer/{Evento}Producer.java`

Descomentar dependencia Kafka no pom.xml.

Adicionar ao application.properties:
```properties
spring.kafka.bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS}
spring.kafka.consumer.group-id={CONSUMER_GROUP}
spring.kafka.consumer.auto-offset-reset=earliest
```

### PASSO 23: Gerar Kubernetes manifests

Criar:
- `k8s/base/deployment.yaml`
- `k8s/base/service.yaml`
- `k8s/base/kustomization.yaml`
- `k8s/overlays/development/kustomization.yaml`
- `k8s/overlays/staging/kustomization.yaml`
- `k8s/overlays/production/kustomization.yaml`

Com health probes apontando para `{CONTEXT_PATH}/actuator/health`.

### PASSO 24: Gerar CI/CD

- `.gitlab-ci.yml`
- `build.sh`
- `Dockerfile`

### PASSO 25: Gerar Maven Wrapper

Executar: `mvn wrapper:wrapper` ou copiar `.mvn/wrapper/` de template.

### PASSO 26: Validar

Apos gerar todos os arquivos:
1. Verificar se a estrutura de pacotes esta correta
2. Executar `./mvnw clean compile -DskipTests` para validar compilacao (se Maven disponivel)
3. Listar todos os arquivos gerados e confirmar com o usuario

---

## Cenarios Especificos

### Se tipo = Proxy/Gateway
- Executar PASSOS 1-20, 23-26
- Pular PASSOS 21-22

### Se tipo = CRUD
- Executar PASSOS 1-10, 16-19, 21, 23-26
- Pular PASSOS 11-15, 20, 22
- No controller, usar endpoints CRUD (GET lista, GET por id, POST, PUT, DELETE)

### Se tipo = Event-Driven
- Executar PASSOS 1-10, 14-19, 22-26
- Pode ou nao ter controller REST (dependendo se expoe API)
- Pode ou nao ter integracao externa

### Se tipo = Hibrido
- Executar TODOS os passos aplicaveis

---

## Regras Importantes

1. **NUNCA pular a geracao de exception handling** - Todo MS precisa de NegocioException + ApiExceptionHandler
2. **NUNCA gerar sem SecurityConfig** - Todo MS precisa de Basic Auth
3. **NUNCA esquecer messages.properties** - Toda excecao usa chave i18n
4. **NUNCA usar @Autowired em campo** - Sempre @RequiredArgsConstructor
5. **NUNCA colocar logica no controller** - Apenas delegar para service
6. **SEMPRE gerar actuator** - Health probes dependem dele
7. **SEMPRE gerar Swagger/OpenAPI** - Documentacao obrigatoria
8. **SEMPRE perguntar ao usuario sobre dominios e endpoints** - Nao assumir
9. **SEMPRE gerar todos os profiles** (LCL, DEV, STG, PRD) - Mesmo que com valores placeholder
10. **SEMPRE gravar log de auditoria** para chamadas externas - Se proxy/gateway

---

## Exemplo de PRD Gerado

Se o usuario pedir para gerar um PRD, use este formato:

```markdown
# PRD - {PROJECT_NAME}

## Identificacao
- **Nome**: {PROJECT_NAME}
- **Descricao**: {DESCRIPTION}
- **Tipo**: {TIPO}
- **Context Path**: {CONTEXT_PATH}

## Integracao Externa
- **Nome**: {INTEGRACAO}
- **Base URL PRD**: {URL}
- **Autenticacao**: {TIPO_AUTH}

## Dominios e Endpoints
| Metodo | Path | Params | Response | Dominio |
|--------|------|--------|----------|---------|
| ... | ... | ... | ... | ... |

## Banco de Dados
- **Tipo**: Oracle
- **Schema**: {SCHEMA}
- **Tabelas de Log**: {LISTA}

## Infraestrutura
- **Namespace K8s**: {NAMESPACE}
- **Deployment**: {DEPLOYMENT}
- **Image**: {IMAGE}
```
