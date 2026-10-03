# Entender Fluxos Spring Boot

## Objetivo
Mapear fluxo completo de uma request em aplicação Spring Boot.

## Camadas típicas

```
HTTP Request
  → Filter Chain (Security, CORS, Logging)
    → Controller (@RestController)
      → Service (@Service)
        → Client (WebClient) / Repository (JPA)
      → Response DTO
    → Exception Handler (@ControllerAdvice)
  → HTTP Response
```

## Como rastrear

1. **Entry point**: buscar `@GetMapping`, `@PostMapping` etc.
2. **Injeções**: verificar constructor do controller
3. **Service layer**: lógica de negócio, validações
4. **Data layer**: chamadas externas ou banco
5. **Error path**: exceções custom, handlers globais

## Perguntas chave
- Qual o endpoint? (`@RequestMapping` na classe)
- Qual o DTO de entrada/saída?
- Há validação (`@Valid`, `@Validated`)?
- Como erros são tratados?
- Há interceptors/filters customizados?
- Qual o fluxo transacional (`@Transactional`)?
