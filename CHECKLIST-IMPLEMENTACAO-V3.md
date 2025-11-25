# ✅ CHECKLIST DE IMPLEMENTAÇÃO - SOLUÇÃO V3 (CSV)

## 📋 PASSO A PASSO

### FASE 1: PREPARAÇÃO (5 minutos)

- [ ] **1.1** Instalar `papaparse`
  ```bash
  cd backend
  npm install papaparse
  npm install --save-dev @types/papaparse
  ```

- [ ] **1.2** Verificar se arquivos foram criados
  ```bash
  ls -l src/services/portal-governo-csv.service.ts
  ls -l src/controllers/portal-governo-csv.controller.ts
  ls -l src/routes/portal-governo-csv.routes.ts
  ls -l src/database/migrations/otimizacoes-portal-governo-csv.sql
  ```

### FASE 2: BANCO DE DADOS (5 minutos)

- [ ] **2.1** Executar script SQL de índices
  ```bash
  psql -d cestas_compras -f src/database/migrations/otimizacoes-portal-governo-csv.sql
  ```

- [ ] **2.2** Verificar índices criados
  ```bash
  psql -d cestas_compras -c "SELECT * FROM pg_indexes WHERE tablename LIKE 'portal_governo_%';"
  ```

### FASE 3: INTEGRAÇÃO NO BACKEND (5 minutos)

- [ ] **3.1** Abrir arquivo `src/server.ts`

- [ ] **3.2** Adicionar import das rotas CSV (procure por outras imports de rotas)
  ```typescript
  const portalGovernoCSVRoutes = (await import('./routes/portal-governo-csv.routes')).default;
  ```

- [ ] **3.3** Registrar rota (procure por `app.use('/api/portal-governo'...`)
  ```typescript
  app.use('/api/portal-governo-csv', portalGovernoCSVRoutes);
  ```

- [ ] **3.4** Salvar arquivo

### FASE 4: TESTES (10 minutos)

- [ ] **4.1** Iniciar backend
  ```bash
  npm run dev
  # Esperar mensagem: "✓ Servidor rodando em http://localhost:3001"
  ```

- [ ] **4.2** Health check
  ```bash
  curl http://localhost:3001/api/portal-governo-csv/health
  ```
  **Resultado esperado:** Status "online"

- [ ] **4.3** Sincronizar dados (UMA VEZ)
  ```bash
  curl -X POST http://localhost:3001/api/portal-governo-csv/sincronizar
  ```
  **Esperar:** "Sincronização concluída" (5-10 segundos)

- [ ] **4.4** Primeira busca
  ```bash
  time curl "http://localhost:3001/api/portal-governo-csv/search?q=papel&tipo=material"
  ```
  **Resultado esperado:** ~4-10ms (banco local é muito rápido!)

- [ ] **4.5** Segunda busca idêntica
  ```bash
  time curl "http://localhost:3001/api/portal-governo-csv/search?q=papel&tipo=material"
  ```
  **Resultado esperado:** <1ms (cache do banco)

### FASE 5: CRON JOB (OPCIONAL - 5 minutos)

- [ ] **5.1** Instalar node-cron (se ainda não tiver)
  ```bash
  npm install node-cron
  npm install --save-dev @types/node-cron
  ```

- [ ] **5.2** Adicionar em `src/server.ts` (após inicializar routes)
  ```typescript
  import cron from 'node-cron';
  import { PortalGovernoCSVService } from './services/portal-governo-csv.service';

  // Sincronizar dados todo dia às 3 da manhã
  cron.schedule('0 3 * * *', async () => {
    console.log('🔄 Sincronizando dados do CSV (cron job automático)...');
    try {
      const csvService = new PortalGovernoCSVService();
      const resultado = await csvService.sincronizarDadosDoCSV();
      console.log(`✓ Sincronização concluída: ${resultado.registros} registros`);
    } catch (error) {
      console.error('✗ Erro na sincronização:', error);
    }
  });
  ```

- [ ] **5.3** Salvar arquivo

### FASE 6: PRODUÇÃO (OPCIONAL)

- [ ] **6.1** Build do projeto
  ```bash
  npm run build
  ```

- [ ] **6.2** Testar modo produção
  ```bash
  npm start
  ```

- [ ] **6.3** Fazer requisições e verificar logs

---

## 🧪 TESTES DE VALIDAÇÃO

### Teste 1: API Responds

```bash
curl -i http://localhost:3001/api/portal-governo-csv/health
```

**Esperado:** HTTP 200 com `"status": "online"`

### Teste 2: Sincronização Funciona

```bash
curl -X POST http://localhost:3001/api/portal-governo-csv/sincronizar | jq '.registros'
```

**Esperado:** Número > 0 (quantidade de registros sincronizados)

### Teste 3: Busca é Rápida

```bash
time curl -s "http://localhost:3001/api/portal-governo-csv/search?q=papel" | jq '.tempoResposta'
```

**Esperado:** `tempoResposta` < 5ms (muito rápido!)

### Teste 4: Paginação Funciona

```bash
curl "http://localhost:3001/api/portal-governo-csv/search?q=papel&pagina=2&tamanhoPagina=50" | jq '.paginacao'
```

**Esperado:** `paginaAtual: 2`, `totalPaginas: > 1`

---

## ⚠️ TROUBLESHOOTING

| Problema | Solução |
|----------|---------|
| **Module not found: papaparse** | `npm install papaparse @types/papaparse` |
| **Health check retorna erro** | Verificar logs do backend, reiniciar `npm run dev` |
| **Sincronização não funciona** | Verificar console do backend, verificar URL da API |
| **Busca retorna empty array** | Executar sincronização: `curl -X POST .../sincronizar` |
| **Busca lenta (>100ms)** | Verificar índices: `psql -c "SELECT * FROM pg_indexes..."` |
| **Erro de permissão no SQL** | Executar como superuser: `psql -U postgres ...` |

---

## 📊 VERIFICAÇÃO FINAL

- [ ] Backend inicia sem erros
- [ ] Health check retorna `"status": "online"`
- [ ] Sincronização completa com sucesso
- [ ] Busca retorna resultados
- [ ] Tempo de resposta < 5ms
- [ ] Paginação funciona
- [ ] Cron job configurado (opcional)

---

## 🎉 PRONTO!

Quando todos os checkboxes acima forem marcados, sua implementação V3 está **100% funcional**!

**Próximos passos:**
1. Testar com dados reais
2. Monitorar performance em produção
3. Ajustar cron job se necessário
4. Documentar em runbook interno

