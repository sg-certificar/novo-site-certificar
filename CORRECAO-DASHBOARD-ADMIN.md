# 🔧 Correção Dashboard Admin - Estatísticas Reais

## ❌ PROBLEMA IDENTIFICADO

**Dashboard mostrava 0 alunos mesmo com alunos cadastrados**

### Causa Raiz:
```javascript
// ANTES (ERRADO):
supabaseClient.from('profiles').select('*', { count: 'exact' })
```

**Problema:** Consultava tabela `profiles` que pode estar vazia ou não ter todos os alunos.

## ✅ SOLUÇÃO IMPLEMENTADA

### Arquivo: `public/admin/script.js` (linha 208)

**ANTES:**
```javascript
async function loadDashboardData() {
    const [alunos, materiais, cursos] = await Promise.all([
        supabaseClient.from('profiles').select('*', { count: 'exact' }),
        supabaseClient.from('materiais').select('*', { count: 'exact' }),
        supabaseClient.from('cursos').select('*', { count: 'exact' })
    ]);

    if (totalAlunosEl) totalAlunosEl.textContent = alunos.count || 0;
    if (totalMateriaisEl) totalMateriaisEl.textContent = materiais.count || 0;
    if (totalCursosEl) totalCursosEl.textContent = cursos.count || 0;
}
```

**DEPOIS:**
```javascript
async function loadDashboardData() {
    console.log('📊 Carregando estatísticas do dashboard...');

    const [alunosAutorizados, materiais, cursos, matriculas] = await Promise.all([
        supabaseClient.from('emails_autorizados').select('*', { count: 'exact' }).eq('autorizado', true),
        supabaseClient.from('materiais').select('*', { count: 'exact' }),
        supabaseClient.from('cursos').select('*', { count: 'exact' }),
        supabaseClient.from('matriculas').select('*', { count: 'exact' })
    ]);

    console.log('📈 Estatísticas:', {
        alunos: alunosAutorizados.count,
        materiais: materiais.count,
        cursos: cursos.count,
        matriculas: matriculas.count
    });

    if (totalAlunosEl) totalAlunosEl.textContent = alunosAutorizados.count || 0;
    if (totalMateriaisEl) totalMateriaisEl.textContent = materiais.count || 0;
    if (totalCursosEl) totalCursosEl.textContent = cursos.count || 0;
}
```

## 📊 QUERIES CORRIGIDAS

### 1. Total de Alunos
```sql
SELECT COUNT(*) FROM emails_autorizados WHERE autorizado = true
```
**Motivo:** Conta alunos autorizados a acessar a plataforma

### 2. Total de Materiais
```sql
SELECT COUNT(*) FROM materiais
```
**Motivo:** Conta todos os materiais uploadados

### 3. Total de Cursos
```sql
SELECT COUNT(*) FROM cursos
```
**Motivo:** Conta cursos cadastrados

### 4. Total de Matrículas (novo)
```sql
SELECT COUNT(*) FROM matriculas
```
**Motivo:** Conta quantas matrículas ativas existem

## 🐛 LOGS DE DEBUG ADICIONADOS

### Console do Admin (F12):

**Ao carregar dashboard:**
```
📊 Carregando estatísticas do dashboard...
📈 Estatísticas: {
  alunos: 5,
  materiais: 12,
  cursos: 3,
  matriculas: 8
}
```

**Se houver erro:**
```
❌ Erro ao carregar dados do dashboard: {erro}
```

## 🎯 ESTATÍSTICAS MOSTRADAS

### Card "Total de Alunos"
- **Consulta:** `emails_autorizados` WHERE `autorizado = true`
- **Significado:** Alunos autorizados para acessar cursos
- **Inclui:** Alunos com códigos de acesso válidos

### Card "Total de Materiais"
- **Consulta:** `materiais` (count)
- **Significado:** PDFs, vídeos, documentos uploadados
- **Inclui:** Todos os materiais de todos os cursos

### Card "Total de Cursos"
- **Consulta:** `cursos` (count)
- **Significado:** Cursos cadastrados no sistema
- **Inclui:** Cursos ativos e inativos

## 📈 MELHORIAS FUTURAS (Opcional)

### Adicionar mais cards:

```javascript
// Total de Matrículas
const totalMatriculasEl = document.getElementById('totalMatriculas');
if (totalMatriculasEl) totalMatriculasEl.textContent = matriculas.count || 0;

// Alunos que já se cadastraram (criaram conta)
const { count: alunosCadastrados } = await supabaseClient
    .from('profiles')
    .select('*', { count: 'exact' });

// Certificados emitidos
const { count: certificadosEmitidos } = await supabaseClient
    .from('certificados')
    .select('*', { count: 'exact' });

// Materiais por curso (média)
const materiaisPorCurso = materiais.count / cursos.count || 0;
```

### Dashboard HTML atualizado:

```html
<div class="stat-card purple">
    <div class="stat-card-header">
        <div>
            <h3>Total de Matrículas</h3>
            <div class="value" id="totalMatriculas">0</div>
        </div>
        <div class="stat-card-icon">📝</div>
    </div>
</div>

<div class="stat-card teal">
    <div class="stat-card-header">
        <div>
            <h3>Certificados Emitidos</h3>
            <div class="value" id="totalCertificados">0</div>
        </div>
        <div class="stat-card-icon">🎓</div>
    </div>
</div>
```

## 🧪 TESTE

### 1. Verificar Estatísticas no Admin

**Acessar:** http://localhost:5174/admin/

**Abrir Console (F12) e verificar:**
```
📊 Carregando estatísticas do dashboard...
📈 Estatísticas: { alunos: X, materiais: Y, cursos: Z, matriculas: W }
```

**Dashboard deve mostrar:**
- Total de Alunos: **número correto** (não mais 0)
- Total de Materiais: **número correto**
- Total de Cursos: **número correto**

### 2. Verificar no Supabase

```sql
-- Contar alunos autorizados
SELECT COUNT(*) FROM emails_autorizados WHERE autorizado = true;

-- Contar materiais
SELECT COUNT(*) FROM materiais;

-- Contar cursos
SELECT COUNT(*) FROM cursos;

-- Contar matrículas
SELECT COUNT(*) FROM matriculas;
```

Os números devem bater!

### 3. Testar Atualização em Tempo Real

1. **Criar novo curso** → Dashboard atualiza
2. **Autorizar novo aluno** → Dashboard atualiza
3. **Upload material** → Dashboard atualiza

## 🔍 TROUBLESHOOTING

### Dashboard mostra 0 em tudo

**Causa:** Tabelas vazias ou erro de permissão

**Solução:**
```javascript
// Ver erro no console
❌ Erro ao carregar dados do dashboard: {mensagem}

// Verificar RLS nas tabelas
-- emails_autorizados deve permitir SELECT para authenticated
-- materiais deve permitir SELECT para authenticated
-- cursos deve permitir SELECT para authenticated
```

### Número de alunos não bate

**Causa:** Pode ter alunos não autorizados

**Verificar:**
```sql
-- Ver todos os emails cadastrados
SELECT email, autorizado FROM emails_autorizados;

-- Ver apenas autorizados
SELECT email FROM emails_autorizados WHERE autorizado = true;
```

### Dashboard não atualiza

**Causa:** Precisa recarregar manualmente

**Solução:**
```javascript
// Adicionar botão de refresh
<button onclick="loadDashboardData()">🔄 Atualizar</button>

// Ou auto-refresh a cada 30 segundos
setInterval(() => {
    loadDashboardData();
}, 30000);
```

## 📝 QUERIES SQL ÚTEIS

### Dashboard Completo
```sql
-- Alunos autorizados
SELECT COUNT(*) as total_alunos
FROM emails_autorizados
WHERE autorizado = true;

-- Materiais por curso
SELECT
    c.titulo,
    COUNT(m.id) as total_materiais
FROM cursos c
LEFT JOIN materiais m ON m.curso_id = c.id
GROUP BY c.id, c.titulo;

-- Matrículas por curso
SELECT
    c.titulo,
    COUNT(ma.id) as total_matriculas,
    AVG(ma.progresso) as progresso_medio
FROM cursos c
LEFT JOIN matriculas ma ON ma.curso_id = c.id
GROUP BY c.id, c.titulo;

-- Certificados emitidos
SELECT COUNT(*) as total_certificados FROM certificados;
```

---

**✅ Dashboard Admin agora mostra estatísticas reais do banco de dados!**
