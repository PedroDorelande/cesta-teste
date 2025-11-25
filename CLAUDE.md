# CLAUDE.md

Arquivo de orientação para Claude Code (claude.ai/code) ao trabalhar com este repositório.

## 🎯 IDIOMA PADRÃO: PORTUGUÊS

**IMPORTANTE:** Claude deve SEMPRE responder em português brasileiro. Todos os comentários, documentação e comunicação devem ser em português.

---

## 📋 Visão Geral do Projeto

Sistema completo para pesquisa de preços e formação de cestas de compras públicas, com integração a múltiplas fontes de dados governamentais (PNCP, TCE, BPS, SINAPI, CONAB, CEASA).

**Stack Tecnológico:**
- **Frontend:** Next.js 15.4.2 (App Router), React 19, TypeScript, Tailwind CSS 4, shadcn/ui
- **Backend:** Node.js, Express, TypeScript, TypeORM, PostgreSQL
- **Autenticação:** JWT com acesso baseado em funções (ADMIN, AUDITOR, ESTABELECIMENTO)

---

## 🚀 Comandos de Desenvolvimento

### Backend (a partir de `/backend`)
```bash
npm install                    # Instalar dependências
npm run dev                    # Iniciar servidor de desenvolvimento com hot-reload (porta 3001)
npm run build                  # Compilar TypeScript
npm start                      # Iniciar servidor de produção
npm run seed:users             # Semear dados de usuários
npm run migrate:users          # Migrar dados de usuários
```

### Frontend (a partir de `/frontend`)
```bash
npm install                    # Instalar dependências
npm run dev                    # Iniciar servidor de desenvolvimento com Turbopack (porta 3000)
npm run build                  # Compilar para produção
npm start                      # Iniciar servidor de produção
npm run lint                   # Executar linter
```

### Migrações de Banco de Dados (a partir de `/backend`)
```bash
npm run migration:generate -- src/database/migrations/NomeMigracao
npm run migration:run          # Aplicar migrações pendentes
npm run migration:revert       # Reverter última migração
npm run typeorm                # CLI do TypeORM
```

---

## 🏗️ Arquitetura

### Estrutura do Backend

**Padrões arquiteturais principais:**

- **Data Source:** TypeORM DataSource configurada em `src/config/database.ts` e `src/data-source.ts` (versão CLI)
  - Inicialização do banco de dados em `initializeDatabase()` que executa migrações automaticamente na inicialização
  - Entidades usam decoradores do TypeORM e class-validator

- **Padrão de Camada de Serviço:** Toda lógica de negócio fica em serviços (`src/services/`)
  - Serviços lidam com integração de API externa E cache em banco de dados
  - Exemplo: `PNCPService` busca da API PNCP, depois armazena em PostgreSQL local para cache
  - Serviços instanciam repositórios diretamente: `AppDataSource.getRepository(EntityName)`

- **Padrão de Integração de API:**
  - APIs governamentais externas (PNCP, TCE) são acessadas via instâncias Axios em serviços
  - URLs base e timeouts configuradas nos construtores de serviço
  - Respostas são mapeadas para entidades TypeORM via utilitários mapper (`src/utils/pncpMapper.ts`)
  - Dados são cacheados localmente em PostgreSQL para desempenho

- **Rotas:** Roteadores Express em `src/routes/` agrupam endpoints por domínio
  - `/api/auth` - Autenticação (login, registro)
  - `/api/procurement` - Dados gerais de licitação
  - `/api/pncp` - Integração PNCP (Portal Nacional de Contratações Públicas)
  - `/api/tce` - Integração TCE (Tribunais de Contas)

- **Middleware:** `src/middlewares/` contém guards de autenticação e validadores
  - Segurança: helmet, cors, rate-limiting configurados em `server.ts`
  - Autenticação JWT via biblioteca jsonwebtoken

**Relacionamentos de Entidades:**
- Entidades PNCP seguem uma hierarquia: `PNCPPca` → `PNCPPcaItem` → `PNCPContratacao` → `PNCPContratacaoDetalhe`
- Todas as entidades PNCP rastreiam timestamp `ultimaSincronizacao` para gerenciamento de cache

### Estrutura do Frontend

**App Router (Next.js 15):**
- `app/page.tsx` - Página de login (pública)
- `app/login/` - Rota de login
- `app/dashboard/` - Área protegida com rotas aninhadas:
  - `cestas/` - Gerenciamento de cestas de compras
  - `produtos/` - Catálogo de produtos
  - `tce/` - Integração de dados TCE
  - `correcao-cesta/`, `correcao-item/` - Fluxos de correção de preços
  - `indices-correcao/` - Índices de correção
  - `relatorio-correcao/` - Relatórios de correção

**Gerenciamento de Estado:**
- React Context (`contexts/auth-context.tsx`) para estado de autenticação global
- TanStack Query para cache de estado do servidor (verificar package.json para uso)
- React Hook Form + Zod para validação de formulários

**Comunicação com API:**
- Instância Axios em `lib/api.ts` com injeção automática de token
- Request interceptor adiciona JWT do localStorage
- Response interceptor trata erros 401 (redireciona para login)
- Helper `getApiUrl()` alterna entre URLs de desenvolvimento/produção

**Biblioteca de Componentes:**
- Componentes shadcn/ui em `components/ui/`
- Primitivos Radix UI + estilo Tailwind CSS
- Suporte para dark mode via next-themes

**Utilitários:**
- `lib/planilha-consolidacao.ts` - Funcionalidade de exportação Excel usando biblioteca xlsx
- `lib/indices-correcao.ts` - Cálculos de índices de correção de preços

---

## 💾 Banco de Dados

**Conexão:**
- Banco de dados PostgreSQL (hospedado em Railway na configuração atual)
- Detalhes de conexão em `backend/.env` (ver `.env.example`)
- Padrão local: `postgresql://postgres:postgres@localhost:5432/cestas_compras`

**Migrações:**
- Migrações são executadas automaticamente na inicialização do servidor
- Localizadas em `backend/src/database/migrations/`
- Padrão de nomenclatura: `{timestamp}-{NomeDescritivo}.ts`
- Usar CLI do TypeORM via `npm run migration:generate`

**Tabelas-chave:**
- `users` - Usuários do sistema com funções
- `government_procurement` - Dados gerais de licitação
- `pncp_pca` - Planos anuais de licitação PNCP
- `pncp_pca_items` - Itens dentro dos PCAs
- `pncp_contratacoes` - Dados de contratação PNCP
- `pncp_contratacao_detalhes` - Detalhes de contratação
- `pncp_fontes_orcamentarias` - Fontes orçamentárias

---

## 🔐 Fluxo de Autenticação

1. Usuário faz login via POST `/api/auth/login` com email/senha
2. Backend valida credenciais e retorna JWT + objeto do usuário
3. Frontend armazena em localStorage (`token`, `user`)
4. Todas as requisições da API incluem header `Authorization: Bearer {token}`
5. Middleware do backend valida JWT em rotas protegidas
6. Tokens inválidos/expirados disparam logout + redirecionamento para /login

**Funções de Usuário:**
- `ADMIN` - Acesso total ao sistema
- `AUDITOR` - Acesso de leitura a relatórios
- `ESTABELECIMENTO` - Usuário de estabelecimento de saúde

---

## 🔧 Variáveis de Ambiente

**Backend (`/backend/.env`):**
```
NODE_ENV=development
PORT=3001
FRONTEND_URL=http://localhost:3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=cestas_compras
JWT_SECRET=sua-chave-secreta
JWT_EXPIRES_IN=7d
LOG_LEVEL=info
```

**Frontend (`/frontend/.env`):**
```
NEXT_PUBLIC_API_URL=http://localhost:3001
```

---

## 🌐 Integrações de API Externa

**PNCP (Portal Nacional de Contratações Públicas):**
- URL Base: `https://pncp.gov.br/api/consulta/v1`
- Serviço: `backend/src/services/pncp.service.ts`
- Endpoints: `/pca`, `/contratacoes`
- Estratégia de cache: Armazenar respostas de API em PostgreSQL, rastrear timestamps de sincronização

**TCE (Tribunais de Contas Estaduais):**
- Serviço: `backend/src/services/tce.service.ts`
- Raspa dados de websites de cortes de contas estaduais
- Múltiplas integrações TCE planejadas (específicas por estado)

---

## 📚 Padrões Comuns

**Adicionando uma nova fonte de dados externa:**
1. Criar entidade em `backend/src/entities/` com decoradores TypeORM
2. Criar migração para a nova tabela
3. Criar serviço em `backend/src/services/` com cliente Axios
4. Implementar lógica de fetch + cache no serviço
5. Criar roteador em `backend/src/routes/`
6. Registrar roteador em `backend/src/server.ts`
7. Criar página frontend em `frontend/app/dashboard/{feature}/`
8. Usar TanStack Query para busca de dados em componentes

**Padrão de Entidade TypeORM:**
```typescript
@Entity('nome_tabela')
export class NomeEntidade {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @IsNotEmpty()
  campo: string;

  @CreateDateColumn()
  criadoEm: Date;

  @UpdateDateColumn()
  atualizadoEm: Date;
}
```

**Padrão de Serviço:**
```typescript
export class ServicoFuncionalidade {
  private repositorio = AppDataSource.getRepository(Entidade);
  private clienteApi: AxiosInstance;

  constructor() {
    this.clienteApi = axios.create({ baseURL: 'URL_API' });
  }

  async buscarECachear() {
    // 1. Buscar de API externa
    // 2. Mapear para entidade
    // 3. Salvar no banco de dados
    // 4. Retornar resposta formatada
  }
}
```

---

## ✅ Testes

Executar verificação de saúde do servidor backend:
```bash
curl http://localhost:3001/health
```

Resposta esperada: `{"status":"ok","timestamp":"..."}`

---

## 🔒 Projeto Dashboard Secreto

**IMPORTANTE PARA CLAUDE CODE:**

Este repositório contém um projeto de dashboard interno secreto armazenado inteiramente em:
```
dashboard-scripts/
├── DASHBOARD-INSTRUCTIONS.md      (Guia completo)
├── run-git-ranking.bat            (Gerador de relatório HTML estático)
├── run-dashboard.bat              (Servidor web interativo ⭐ NOVO)
├── git-ranking.sh
├── git-complexity-analysis.sh
├── git-task-contribution-analysis.sh
├── start.sh
├── server.js                      (Servidor web Node.js, porta 3002)
├── instruçoes.sh
└── public/                        (UI Bootstrap 5 para servidor web)
```

### Dois Modos de Dashboard

1. **Modo Relatório Estático** (`run-git-ranking.bat`)
   - Gera um arquivo HTML estático único
   - Nenhum servidor necessário (usa apenas Git Bash/WSL)
   - Bom para compartilhar relatórios

2. **Modo Web Interativo** (`run-dashboard.bat`) ⭐ RECOMENDADO
   - Executa servidor Node.js na porta 3002
   - Interface web ao vivo com 3 scripts de análise
   - Atalhos de teclado, filtros, execução sob demanda
   - Servidor executa no terminal, para quando fechado
   - ✨ **Portável:** Funciona no projeto completo OU em qualquer lugar do Windows de forma standalone

### Regras a Seguir

1. **NUNCA fazer commit da pasta `dashboard-scripts/`** - Deve sempre ficar em `.gitignore`
2. **NUNCA remover entrada `.gitignore` para `dashboard-scripts/`**
3. **SEMPRE validar** antes de operações git que os arquivos do dashboard permaneçam não rastreados
4. **LER PRIMEIRO:** Ver `dashboard-scripts/DASHBOARD-INSTRUCTIONS.md` para detalhes completos

### Checklist de Verificação

Antes de fazer push/commit:
```bash
git status  # Verificar que pasta dashboard-scripts/ NÃO está staged
```

Esperado: `nothing to commit, working tree clean` (dashboard-scripts/ não rastreado)

---

## 📝 Notas

- Sincronização de banco de dados está definida como `false` - sempre usar migrações
- Frontend usa Server Components por padrão (Next.js 15 App Router)
- Rate limiting: 100 requisições por 15 minutos por IP em `/api/*`
- CORS está configurado para aceitar requisições de `FRONTEND_URL`
- Logging em modo desenvolvimento mostra queries SQL do TypeORM
