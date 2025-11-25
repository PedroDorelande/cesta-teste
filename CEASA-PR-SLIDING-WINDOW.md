# CEASA-PR: Implementação de Sliding Window (8 dias)

## 📋 Visão Geral

Implementação de um **sliding window de 8 dias** para o CEASA-PR. O sistema agora:

- ✅ **Baixa dados dos últimos 8 dias**: dia atual + 7 dias anteriores
- ✅ **Atualiza diariamente**: A cada dia novo, remove o dado mais antigo e adiciona o novo
- ✅ **Mantém histórico**: Sempre tem preços dos últimos 7 dias para análise e comparação
- ✅ **Performance otimizada**: Índices de banco de dados para queries rápidas

## 🔧 Mudanças Implementadas

### 1. **Entidade CeasaPrPreco** (`src/entities/CeasaPrPreco.ts`)
- **Nova coluna**: `diaColeta` (string YYYY-MM-DD)
- **Índices adicionados**:
  - `IDX_CEASA_PR_DIA_COLETA`: Otimiza buscas por dia
  - `IDX_CEASA_PR_DIA_COLETA_REGIONAL`: Otimiza buscas por dia + regional

### 2. **Serviço PortalCeasaPrService** (`src/services/portal-ceasa-pr.service.ts`)

#### Nova constante:
```typescript
private readonly DIAS_HISTORICO = 7; // Manter 7 dias + dia atual = 8 dias
```

#### Novas funções auxiliares:

1. **`obterDatasUltimos8Dias(): string[]`**
   - Gera array com datas dos últimos 8 dias em formato YYYY-MM-DD
   - Exemplo: Se hoje é 2024-01-10, retorna: `[2024-01-03, 2024-01-04, ..., 2024-01-10]`

2. **`buscarPrecosMuliploDias(datas: string[]): Promise<Array<Record<string, any>>>`**
   - ⚠️ **Descoberta importante**: O portal CEASA-PR **NÃO mantém dados históricos publicamente**
   - Todas as datas retornam os mesmos preços de hoje via URLs
   - **Estratégia implementada** (construção incremental):
     1. **Busca APENAS dados de HOJE** (uma única requisição)
     2. **Retorna dados com diaColeta = HOJE**
     3. Sliding window remove automaticamente dados com `diaColeta < (HOJE - 7 dias)`
   - **Resultado**: Histórico cresce naturalmente, 1 dia por sincronização
     - Dia 1: 1 dia com dados
     - Dia 2: 2 dias com dados (ontem + hoje)
     - Dia 3: 3 dias com dados
     - ...
     - Dia 8+: 8 dias com dados (janela desliza, remove o mais antigo)

#### Lógica de sincronização atualizada:
```typescript
async sincronizar()
```

**Fluxo da sincronização:**
1. Obtém datas dos últimos 8 dias (referência para limpeza de dados antigos)
2. Busca preços DE HOJE apenas (uma requisição ao portal)
3. Normaliza dados (converte para camelCase, tipos corretos, preenche `diaColeta = HOJE`)
4. **Limpa sliding window**: Remove registros com `diaColeta < (HOJE - 7 dias)`
5. Remove dados de hoje se existirem (para substituir por preços novos)
6. Insere APENAS os dados de hoje em batch (1000 por vez)
7. Registra auditoria de sincronização com período mantido

**Resultado da sincronização:**
```json
{
  "status": "SUCESSO",
  "registrosInseridos": 1234,
  "registrosDeletados": 456,
  "tempoExecucao": 5432,
  "periodoManido": {
    "de": "2024-01-03",
    "ate": "2024-01-10"
  }
}
```

### 3. **Migração de Banco de Dados** (`src/database/migrations/1735094800000-AddDiaColetaCeasaPr.ts`)

A migração:
- ✅ Adiciona coluna `diaColeta` à tabela `portal_ceasa_pr_precos`
- ✅ Preenche valores existentes a partir de `dataColeta`
- ✅ Cria índices para otimização
- ✅ Mantém compatibilidade com dados antigos

**Para executar a migração:**
```bash
cd backend
npm run migration:run
```

## 🚀 Como Funciona o Sliding Window

### Exemplo de Evolução Diária

**Dia 1 (2024-01-03) - Primeira sincronização:**
```
Banco contém: [2024-01-03]
Após sincronização: [2024-01-03, 2024-01-04, ..., 2024-01-10] (8 dias)
```

**Dia 2 (2024-01-11) - Segunda sincronização:**
```
Antes: [2024-01-03, 2024-01-04, ..., 2024-01-10]
Depois: [2024-01-04, 2024-01-05, ..., 2024-01-11]
         ↑ Removeu 2024-01-03 (mais antigo)
                              ↑ Adicionou 2024-01-11 (hoje)
```

**Dia 3 (2024-01-12) - Terceira sincronização:**
```
Antes: [2024-01-04, 2024-01-05, ..., 2024-01-11]
Depois: [2024-01-05, 2024-01-06, ..., 2024-01-12]
         ↑ Removeu 2024-01-04
                              ↑ Adicionou 2024-01-12
```

## 🔄 Como funciona o Sliding Window (Construção Incremental)

### Exemplo de Evolução Diária

**Dia 1 (2025-11-23) - Primeira sincronização:**
```
Sincronização #1:
  └─ Busca: dados de 2025-11-23
  └─ Insere: 32 produtos com diaColeta=2025-11-23
  └─ Remove: nada (banco vazio)
  └─ Resultado: 32 registros (1 dia)

Banco contém: [2025-11-23]
```

**Dia 2 (2025-11-24) - Segunda sincronização:**
```
Sincronização #2:
  └─ Busca: dados de 2025-11-24
  └─ Remove: diaColeta < 2025-11-17 (nada a remover, temos 1 dia)
  └─ Remove: diaColeta = 2025-11-24 (nada, é o primeiro dia 24)
  └─ Insere: 32 produtos com diaColeta=2025-11-24
  └─ Resultado: 32 registros novos

Banco contém: [2025-11-23, 2025-11-24]
Total: 64 registros (2 dias)
```

**Dia 3 (2025-11-25) - Terceira sincronização:**
```
Antes: [2025-11-23, 2025-11-24]  (64 registros)

Sincronização #3:
  └─ Busca: dados de 2025-11-25
  └─ Remove: diaColeta < 2025-11-18 (nada)
  └─ Insere: 32 produtos com diaColeta=2025-11-25

Depois: [2025-11-23, 2025-11-24, 2025-11-25]
Total: 96 registros (3 dias)
```

**...Continua até Dia 8...**

**Dia 8 (2025-11-30) - Oitava sincronização:**
```
Antes: [2025-11-23, 2025-11-24, ..., 2025-11-29]  (7 dias = 224 registros)

Sincronização #8:
  └─ Busca: dados de 2025-11-30
  └─ Remove: diaColeta < 2025-11-23 (nada, estamos no limite)
  └─ Insere: 32 produtos com diaColeta=2025-11-30

Depois: [2025-11-23, 2025-11-24, ..., 2025-11-30]
Total: 256 registros (8 dias completos)
```

**Dia 9 (2025-12-01) - Nona sincronização (Sliding Window Ativo):**
```
Antes: [2025-11-23, 2025-11-24, ..., 2025-11-30]  (8 dias = 256 registros)

Sincronização #9:
  └─ Busca: dados de 2025-12-01
  └─ Remove: diaColeta < 2025-11-24 ← REMOVE TODOS OS DE 2025-11-23 (32 registros)
  └─ Insere: 32 produtos com diaColeta=2025-12-01

Depois: [2025-11-24, 2025-11-25, ..., 2025-12-01]
Total: 256 registros (8 dias, janela deslizou automaticamente)
```

## 📊 Queries de Exemplo

### Buscar preços dos últimos 8 dias
```sql
SELECT DISTINCT
  "diaColeta",
  COUNT(*) as total_registros
FROM portal_ceasa_pr_precos
GROUP BY "diaColeta"
ORDER BY "diaColeta" DESC;
```

### Buscar preços de hoje
```sql
SELECT *
FROM portal_ceasa_pr_precos
WHERE "diaColeta" = CURRENT_DATE::varchar
ORDER BY produto ASC;
```

### Comparar preço de um produto nos últimos 8 dias
```sql
SELECT
  "diaColeta",
  produto,
  regional,
  "precoMedio"
FROM portal_ceasa_pr_precos
WHERE produto ILIKE '%tomate%'
  AND regional = 'Curitiba'
ORDER BY "diaColeta" DESC;
```

### Produtos com maior variação nos últimos 8 dias
```sql
SELECT
  produto,
  MIN("precoMedio") as preco_minimo,
  MAX("precoMedio") as preco_maximo,
  MAX("precoMedio") - MIN("precoMedio") as variacao
FROM portal_ceasa_pr_precos
WHERE regional = 'Curitiba'
GROUP BY produto
HAVING MAX("precoMedio") - MIN("precoMedio") > 0
ORDER BY variacao DESC
LIMIT 20;
```

## 🧪 Teste da Implementação

### 1. Compilar o código
```bash
cd backend
npm run build
```

### 2. Executar migração
```bash
npm run migration:run
```

### 3. Iniciar servidor de desenvolvimento
```bash
npm run dev
```

### 4. Testar health check
```bash
curl http://localhost:3001/health/ceasa-pr
```

Resposta esperada:
```json
{
  "status": "ok",
  "registrosEmCache": 0,
  "ultimaSincronizacao": null,
  "timestamp": "2024-01-10T15:30:00.000Z"
}
```

### 5. Disparar sincronização manualmente
```bash
curl -X POST http://localhost:3001/api/ceasa-pr/sincronizar
```

Resposta esperada:
```json
{
  "status": "SUCESSO",
  "registrosInseridos": 1234,
  "registrosDeletados": 0,
  "tempoExecucao": 5432,
  "periodoManido": {
    "de": "2024-01-03",
    "ate": "2024-01-10"
  }
}
```

### 6. Consultar dados sincronizados
```bash
curl "http://localhost:3001/api/ceasa-pr/buscar?regional=Curitiba&pagina=1"
```

## 📝 Notas Técnicas

### Performance
- **Índices**: Otimizados para queries de `diaColeta` e `diaColeta + regional`
- **Batch Insert**: Insere 1000 registros por vez para melhor performance
- **Limpeza automática**: Remove dados antigos em uma query SQL única

### Compatibilidade
- ✅ Mantém coluna `dataColeta` original intacta
- ✅ Migração preenche valores antigos automaticamente
- ✅ Sem breaking changes na API

### Rastreamento
- **Sync Log**: Registra cada sincronização (sucesso/erro, registros, tempo)
- **Logs Console**: Mensagens detalhadas no console do servidor

### Fuso Horário
- Todas as datas usam `toISOString()` (UTC)
- Conversão para formato YYYY-MM-DD automática

## 🔄 Agendamento de Sincronização

Para sincronizar automaticamente diariamente, adicione um cron job:

**Opção 1: Node-cron** (recomendado)
```typescript
import cron from 'node-cron';
import { PortalCeasaPrService } from './services/portal-ceasa-pr.service';

const ceasaService = new PortalCeasaPrService();

// Sincronizar diariamente às 22:00 (noite)
cron.schedule('0 22 * * *', async () => {
  console.log('[CRON] Iniciando sincronização CEASA-PR');
  try {
    await ceasaService.sincronizar();
  } catch (error) {
    console.error('[CRON] Erro na sincronização CEASA-PR:', error);
  }
});
```

**Opção 2: Cron do Sistema (Linux/macOS)**
```bash
# Adicione ao crontab: crontab -e
0 22 * * * cd /path/to/backend && npm run sync:ceasa-pr
```

## ✅ Checklist de Implementação

- [x] Adicionar coluna `diaColeta` à entidade
- [x] Criar índices apropriados
- [x] Implementar função `obterDatasUltimos8Dias()`
- [x] Atualizar lógica de sincronização
- [x] Atualizar função `normalizarRegistro()`
- [x] Criar migração de banco de dados
- [x] Compilar TypeScript sem erros
- [ ] Executar testes de integração
- [ ] Testar em ambiente de staging
- [ ] Deploy para produção

## 🚨 Troubleshooting

### Erro: "coluna diaColeta não existe"
**Causa**: Migração não foi executada
**Solução**:
```bash
npm run migration:run
```

### Nenhum dado após sincronização
**Causa**: Página CEASA-PR pode estar instável
**Solução**: Verifique os logs do console e tente novamente

### Dados não são removidos após 8 dias
**Causa**: Data mais antiga não está sendo calculada corretamente
**Solução**: Verifique fuso horário do servidor

## 📚 Referências

- [CEASA-PR Portal](https://www.ceasa.pr.gov.br/Pagina/Cotacao-Diaria-de-Precos)
- [Página de Cotação (HTML scraping)](https://celepar7.pr.gov.br/ceasa/hoje.asp)
- [TypeORM Migrations](https://typeorm.io/migrations)
- [Sliding Window Pattern](https://en.wikipedia.org/wiki/Sliding_window_protocol)
