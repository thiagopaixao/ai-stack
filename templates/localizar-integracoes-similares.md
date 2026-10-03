# Localizar Integrações Similares

## Objetivo
Encontrar implementações existentes de integrações para usar como referência.

## Buscar por tipo

### HTTP Clients (WebClient)
```
rg "WebClient" --type java -l
rg "\.uri\(|\.retrieve\(\)" --type java
```

### Database
```
rg "@Repository|@Query|JpaRepository" --type java -l
rg "nativeQuery.*=.*true" --type java
```

### Cache
```
rg "@Cacheable|@CacheEvict|RedisTemplate" --type java -l
```

### Messaging
```
rg "@KafkaListener|@RabbitListener|JmsTemplate" --type java -l
```

### Security
```
rg "SecurityFilterChain|@PreAuthorize|@Secured" --type java -l
```

## Workflow
1. Identificar tipo de integração necessária
2. Buscar exemplos existentes no codebase
3. Analisar padrão usado (config, error handling, retry)
4. Replicar padrão para nova integração
