# Analisar Blast Radius

## Objetivo
Avaliar impacto de uma mudança antes de implementá-la.

## Checklist

1. **Quem chama este código?**
   - Serena: find references do símbolo
   - Buscar usages do método/classe

2. **Quem depende deste DTO/model?**
   - Mapear serialization/deserialization
   - Verificar contratos de API
   - Checar mapeamentos (MapStruct, manual)

3. **Testes existentes**
   - Testes unitários que cobrem o código
   - Testes de integração relacionados
   - Cobertura real vs percebida

4. **Configurações afetadas**
   - Properties referenciando o componente
   - Beans condicionais (@ConditionalOn...)
   - Profiles que alteram comportamento

5. **Integrações downstream**
   - APIs consumidas por outros serviços
   - Eventos publicados
   - Tabelas compartilhadas

## Output esperado
- Lista de arquivos potencialmente afetados
- Classificação: alto/médio/baixo risco
- Testes a executar para validação
