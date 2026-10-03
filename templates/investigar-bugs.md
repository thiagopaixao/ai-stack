# Investigar Bugs

## Objetivo
Investigar e resolver bugs em sistema legado Spring Boot.

## Workflow

1. **Reproduzir o cenário**
   - Identificar endpoint/fluxo afetado
   - Verificar logs e stack traces
   - Mapear input → output esperado vs real

2. **Rastrear o fluxo**
   - Usar Serena: find_symbol, find references
   - Seguir Controller → Service → Client/Repository
   - Identificar transformações de dados

3. **Identificar causa raiz**
   - Verificar null handling
   - Checar mapeamento de DTOs
   - Verificar configuração (properties, profiles)
   - Checar tratamento de exceções

4. **Analisar blast radius**
   - Quem mais usa o método afetado?
   - Há testes que cobrem o cenário?
   - Outras integrações afetadas?

5. **Corrigir e validar**
   - Fix mínimo e localizado
   - Adicionar teste de regressão
   - Verificar build completo
