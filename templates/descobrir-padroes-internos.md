# Descobrir Padrões Internos

## Objetivo
Identificar padrões recorrentes no codebase para reuso e consistência.

## Padrões a buscar

### Estruturais
- Package organization por feature vs por layer
- DTO patterns (records, builders, mappers)
- Exception handling (hierarchy, ControllerAdvice)
- Config patterns (properties, beans)

### Comportamentais
- Retry/circuit breaker patterns
- Caching strategies (Redis, in-memory)
- Validation (Bean Validation, custom)
- Logging/audit patterns

### Integrações
- HTTP client patterns (WebClient config)
- Message queue patterns (Kafka, RabbitMQ)
- Database access (JPA, native queries)
- Authentication/authorization

## Comandos úteis
- `rg "@Service" --type java -l` — listar services
- `rg "WebClient" --type java -l` — listar clientes HTTP
- `rg "@ControllerAdvice" --type java` — exception handlers
- `rg "implements.*Repository" --type java` — custom repos
