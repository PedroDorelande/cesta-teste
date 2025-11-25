# Guia de Teste Manual - Requisitos 22 e 23

## Pré-requisitos

1. **Backend rodando:** `npm run dev` em `/backend` (porta 3001)
2. **Frontend rodando:** `npm run dev` em `/frontend` (porta 3000)
3. **PostgreSQL rodando** com banco de dados `cestas_compras`
4. **Resend API configurada** (opcional - se não tiver, emails aparecem no console)

---

## TESTE DO REQUISITO 22

### O que é o Requisito 22?
"O sistema deverá possuir módulo ou aplicativo para cotação eletrônica, possibilitado o disparo de e-mail (com link para acesso ao sistema/aplicativo de cotação) para os fornecedores incluídos na cesta de preços. O acesso ao sistema/aplicativo de cotação eletrônica por parte dos fornecedores deverá ocorrer por meio de login/senha."

---

## PARTE 1: Testar Envio de E-mail com Link

### Passo 1: Criar uma Cesta de Compras
1. Acesse http://localhost:3000 (login como admin/usuário)
2. Vá para **Dashboard > Cestas**
3. Clique em **"Nova Cesta"**
4. Preencha:
   - **Descrição:** "Cesta Teste REQ 22-23"
   - **Data:** Hoje
   - **Tipo de Cálculo:** Média
   - **Clique em Criar**

### Passo 2: Adicionar Itens à Cesta
1. Após criar, clique na cesta criada
2. Vá para a aba **"Itens"**
3. Clique em **"Adicionar Item"**
4. Preencha:
   - **Descrição:** "Papel A4"
   - **Unidade:** Resma
   - **Quantidade:** 10
   - **Clique em Salvar**

### Passo 3: Adicionar Fornecedor à Cesta
1. Vá para aba **"Fornecedores"**
2. Clique em **"Adicionar Fornecedor"**
3. Preencha:
   - **CNPJ:** 12.345.678/0001-90 (ou qualquer CNPJ válido)
   - **Razão Social:** "Fornecedor Teste"
   - **Email:** seu_email@gmail.com (ou email de teste)
   - **Endereço:** Rua Teste, 123
   - **CEP:** 12345-678
   - **Cidade:** São Paulo
   - **Clique em Salvar**

### Passo 4: Enviar Convite por E-mail ✉️
1. Volta para aba **"Fornecedores"**
2. Clique em **"Enviar Convites"**
3. **Resultado esperado:**
   - ✅ Mensagem de sucesso aparece
   - ✅ Se Resend está configurado: Email é enviado
   - ✅ Se Resend NÃO está configurado: Verifique o console do backend (`npm run dev`)
     - Procure por: "Email enviado para: seu_email@gmail.com"
     - Procure pelo link: `http://localhost:3000/convite?token=...`

---

## PARTE 2: Testar Login do Fornecedor

### Passo 5: Acessar o Link de Cotação
**Opção A - Se você recebeu o email:**
1. Abra o email recebido
2. Clique no link de convite

**Opção B - Se o email foi para console:**
1. Copie a URL do console: `http://localhost:3000/convite?token=abc123...`
2. Cole em uma nova aba do navegador

### Passo 6: Registrar como Fornecedor (se for primeira vez)
1. Clique em **"Criar Conta"**
2. Preencha:
   - **Email:** seu_email@gmail.com
   - **Senha:** qualquer_senha_123
   - **Confirmar Senha:** qualquer_senha_123
   - **Clique em Registrar**

### Passo 7: Fazer Login como Fornecedor
**Se já tem conta:**
1. Vá para http://localhost:3000/fornecedor/login
2. Preencha:
   - **Email:** seu_email@gmail.com
   - **Senha:** qualquer_senha_123
   - **Clique em Login**

**Resultado esperado:**
- ✅ Login bem-sucedido
- ✅ Redirecionado para dashboard do fornecedor
- ✅ Vê lista de cotações pendentes

---

## TESTE DO REQUISITO 23

### O que é o Requisito 23?
"A ferramenta de cotação deverá apresentar ao fornecedor as informações do orçamento: entidade solicitante, data, objeto, lista de itens (item, descrição, unidade de medida, quantidade) e possibilitar o registro: do endereço, CEP, cidade, prazo de validade da cotação, nome completo e CPF do responsável, local e data, além de espaço para registro de observações da cotação de preços"

---

## PARTE 3: Verificar Campos Apresentados (Informações)

### Passo 8: Abrir Cotação
1. No dashboard do fornecedor, clique na cotação **"Cesta Teste REQ 22-23"**
2. Página abre com formulário de cotação

### Verificar INFORMAÇÕES APRESENTADAS (que o fornecedor vê):
✅ **Verificar se aparece:**
- [ ] **Entidade Solicitante:** Nome do órgão/prefeitura (no topo)
- [ ] **Data:** Data da solicitação
- [ ] **Objeto:** Descrição "Cesta Teste REQ 22-23"
- [ ] **Lista de Itens com:**
  - [ ] Número do item (ID)
  - [ ] Descrição: "Papel A4"
  - [ ] Unidade: "Resma"
  - [ ] Quantidade: "10"

---

## PARTE 4: Verificar Campos para Preenchimento (REQ 23)

### Passo 9: Verificar Campos Obrigatórios
Na mesma página de cotação, procure pelos seguintes campos e preencha:

**Seção de Entrega:**
- [ ] **Endereço:** Digite um endereço (ex: Rua Principal, 456)
- [ ] **CEP:** Digite um CEP (ex: 87654-321)
- [ ] **Cidade:** Selecione ou digite a cidade

**Seção de Responsável:**
- [ ] **Nome Completo:** Digite o nome completo (ex: João Silva)
- [ ] **CPF:** Digite um CPF válido (ex: 123.456.789-00)

**Seção de Cotação:**
- [ ] **Local:** Campo para indicar local da cotação (ex: Matriz)
- [ ] **Data:** Data da cotação (preenchida automaticamente com hoje)
- [ ] **Prazo de Validade:** Digite quantos dias (ex: 30)
- [ ] **Observações Gerais:** Digite alguma observação (ex: "Preço válido por 30 dias")

---

## PARTE 5: Testar Preenchimento de Itens

### Passo 10: Preencher Informações dos Itens
Na tabela de itens, para o item "Papel A4", preencha:

Para cada item, deve ter:
- [ ] **Marca:** Digite marca (ex: "Chamex")
- [ ] **Valor Unitário:** Digite o preço (ex: "25.50")
- [ ] **Valor Total:** Deve calcular automaticamente (10 × 25.50 = 255.00)
- [ ] **Observações do Item:** Campo para observações específicas do item

**⚠️ IMPORTANTE:** Se o item for medicamento, deve aparecer também:
- [ ] **Registro ANVISA:** Campo para número de registro

---

## PARTE 6: Testar Auto-save e Assinatura

### Passo 11: Verificar Auto-save
1. Preencha alguns campos
2. **Aguarde 3 segundos**
3. Verifique se aparece mensagem: "✓ Salvo"
4. **Resultado esperado:** Status muda de "Salvando..." para "Salvo"

### Passo 12: Assinar a Cotação
1. Vá para seção **"Assinatura Digital"**
2. Escolha **"Assinatura Simples"** (mais fácil para teste)
3. Preencha:
   - **Nome:** João Silva
   - **CPF:** 123.456.789-00
   - **Senha:** sua_senha_fornecedor
4. Clique em **"Assinar"**

**Resultado esperado:**
- ✅ Aparece mensagem de sucesso
- ✅ Timestamp de assinatura registrado
- ✅ Cotação muda para status "ASSINADA"

---

## PARTE 7: Testar Envio de Cotação

### Passo 13: Enviar Cotação
1. Clique em **"Enviar Cotação"**
2. Confirme a ação

**Resultado esperado:**
- ✅ Mensagem: "Cotação enviada com sucesso"
- ✅ Status muda para "ENVIADA"
- ✅ Botão de editar fica desabilitado

---

## PARTE 8: Verificar PDF (BONUS)

### Passo 14: Baixar PDF da Cotação
1. Clique em **"Download PDF"** (se disponível)
2. PDF abre ou baixa

**Resultado esperado:**
- ✅ PDF contém todos os dados preenchidos
- ✅ Mostra assinatura digital
- ✅ Lista completa de itens com valores

---

## CHECKLIST DE SUCESSO

### Requisito 22 ✅
- [ ] Email com link foi enviado/apareceu
- [ ] Link de convite funciona
- [ ] Fornecedor consegue registrar conta
- [ ] Fornecedor consegue fazer login
- [ ] Fornecedor acessa formulário de cotação

### Requisito 23 ✅
- [ ] Aparecem: Entidade, Data, Objeto, Lista de Itens
- [ ] Campo para Endereço funciona
- [ ] Campo para CEP funciona
- [ ] Campo para Cidade funciona
- [ ] Campo para Nome do Responsável funciona
- [ ] Campo para CPF funciona
- [ ] Campo para Local funciona
- [ ] Campo para Data funciona
- [ ] Campo para Prazo de Validade funciona
- [ ] Campo para Observações funciona
- [ ] Auto-save funciona
- [ ] Assinatura funciona
- [ ] Envio funciona

---

## DICAS ÚTEIS

### Se Resend não está configurado:
1. Verifique o console do backend
2. Procure por linhas com "Email enviado"
3. Copie a URL do link do console

### Se algo não funcionar:
1. Verifique se backend/frontend estão rodando
2. Abra console do navegador (F12 > Console) para ver erros
3. Verifique logs do backend

### Para limpar dados de teste:
```bash
# No terminal do backend
npm run migration:revert  # Volta última migração
npm run migration:run     # Executa migrações novamente
```

---

## TESTE RÁPIDO (5 MINUTOS)

Se não quer fazer tudo, faça isso:

1. Criar cesta com 1 item
2. Adicionar 1 fornecedor
3. Enviar convite
4. Copiar link do console (ou email)
5. Abrir link em aba incógnita
6. Registrar como fornecedor
7. Fazer login
8. Preencher cotação (endereço, CEP, cidade, nome, CPF, local, data, observações)
9. Preencher item (marca, valor unitário)
10. Assinar e enviar

**Tempo esperado:** 5 minutos

---

## CONTATO/SUPORTE

Se encontrar problemas:
- Verifique se banco de dados está rodando
- Verifique variáveis de ambiente (.env)
- Verifique se Resend API key está configurada (opcional)
- Reinicie backend e frontend
