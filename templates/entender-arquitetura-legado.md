# Entender Arquitetura Legado

## Objetivo
Mapear a arquitetura de um sistema Spring Boot legado.

## Passos

1. **Identificar camadas**
   - Buscar packages: controller, service, repository, client, model, dto, config
   - `serena find_symbol` para classes principais

2. **Mapear integrações externas**
   - Buscar WebClient, RestTemplate, FeignClient
   - Identificar URLs configuradas em application.yml

3. **Identificar padrões**
   - Injeção de dependência (constructor injection vs field)
   - Tratamento de erros (ControllerAdvice, try/catch)
   - Logging patterns
   - Security config

4. **Banco de dados**
   - Listar entities (@Entity)
   - Verificar migrations (Flyway/Liquibase)
   - Mapear repositories e queries customizadas

5. **Gerar mapa**
   - Diagrama de dependências entre packages
   - Fluxo request → response
   - Integrações externas

## Perguntas para o agente
- "Quais são os endpoints expostos?"
- "Quais integrações externas existem?"
- "Como funciona a autenticação?"
- "Qual o fluxo de dados para [feature]?"
