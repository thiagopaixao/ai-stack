# Implementar Feature via PRD

## Objetivo
Implementar uma feature a partir de um PRD (Product Requirements Document).

## Passos

1. **Analisar PRD**
   - Identificar requisitos funcionais
   - Identificar requisitos não-funcionais
   - Mapear integrações necessárias

2. **Localizar código similar**
   - Usar Serena para buscar padrões existentes
   - Buscar features análogas no mesmo projeto
   - Identificar convenções de naming/estrutura

3. **Planejar implementação**
   - Listar arquivos a criar/modificar
   - Definir ordem de implementação
   - Identificar testes necessários

4. **Implementar**
   - Seguir padrões existentes (Lombok, DTOs, etc.)
   - Criar testes unitários
   - Manter consistência com codebase existente

5. **Validar**
   - Build: `./mvnw clean verify`
   - Testes: `./mvnw test`
   - Review: blast radius analysis

## Template PRD mínimo
```markdown
# Feature: [Nome]
## Contexto
## Requisitos Funcionais
## Requisitos Não-Funcionais
## Integrações
## Critérios de Aceite
```
