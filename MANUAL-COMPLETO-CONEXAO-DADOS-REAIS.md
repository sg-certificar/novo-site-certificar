# 🔧 MANUAL COMPLETO - Conexão com Dados Reais

## 🎯 OBJETIVO

Garantir que todo o sistema (Admin + Área do Aluno) use apenas dados reais do Supabase, sem hardcoded.

---

## ✅ CORREÇÕES IMPLEMENTADAS

### **1. ÁREA DO ALUNO - Matrícula Automática**

**Arquivo**: `public/area-aluno.html` (linhas 1114-1136)

#### **PROBLEMA ANTERIOR**
Matrícula criada sem campo `aluno_email`, dificultando queries futuras.

#### **SOLUÇÃO IMPLEMENTADA**
```javascript
// Criar matrículas com aluno_email
const matriculas = cursosUnicos.map(cursoId => ({
    aluno_id: userId,
    aluno_email: email, // ← ADICIONADO
    curso_id: cursoId,
    progresso: 0,
    data_matricula: new Date().toISOString()
}));

const { data: matriculasData, error: matriculaError } = await supabaseClient
    .from('matriculas')
    .insert(matriculas)
    .select(); // ← Retorna dados criados para log

if (matriculaError) {
    console.error('❌ Erro ao criar matrículas:', matriculaError);
} else {
    console.log('✅ Matrículas criadas com sucesso:', matriculasData);
}
```

**Benefícios**:
- ✅ Permite buscar matrículas por email ou ID
- ✅ Facilita JOIN com `emails_autorizados`
- ✅ Logs detalhados para debug

---

### **2. ÁREA DO ALUNO - Logs Detalhados**

**Arquivo**: `public/area-aluno.html` (linhas 1232-1285)

#### **ANTES**
```javascript
console.log('👤 Carregando dados para usuário:', currentUser.id);
const { data: matriculas } = await supabaseClient
    .from('matriculas')
    .select('*')
    .eq('aluno_id', currentUser.id);
```

#### **DEPOIS**
```javascript
console.log('👤 Carregando dados para usuário:', {
    id: currentUser.id,
    email: currentUser.email
});

const { data: matriculas } = await supabaseClient
    .from('matriculas')
    .select(`
        *,
        cursos (
            id,
            titulo,
            carga_horaria,
            descricao
        )
    `)
    .eq('aluno_id', currentUser.id);

console.log('📋 Matrículas encontradas:', matriculas);
console.log('📊 Total de matrículas:', matriculas?.length || 0);

if (!matriculas || matriculas.length === 0) {
    console.warn('⚠️ Nenhuma matrícula encontrada para este usuário');
    console.log('💡 Verifique se:');
    console.log('   1. O aluno foi autorizado em emails_autorizados');
    console.log('   2. Foi criada uma matrícula na tabela matriculas');
    console.log('   3. O aluno_id da matrícula corresponde ao user.id');

    // Mostrar mensagem amigável na UI
    updateStatistics(0, 0, 0);
    return;
}
```

**Benefícios**:
- ✅ Debug fácil com console logs
- ✅ Mensagens de erro úteis
- ✅ UI mostra aviso quando não há matrículas

---

### **3. DASHBOARD ADMIN - Queries Corretas**

**Arquivo**: `public/admin/script.js` (linhas 208-237)

#### **JÁ ESTAVA CORRETO**
```javascript
async function loadDashboardData() {
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

**Status**: ✅ Usando dados reais

---

### **4. CERTIFICADOS ADMIN - Busca em emails_autorizados**

**Arquivo**: `public/admin/script.js` (linhas 879-966)

#### **PROBLEMA ANTERIOR**
Buscava em `profiles` que pode não existir.

#### **SOLUÇÃO IMPLEMENTADA**
```javascript
async function loadAlunosPorCurso() {
    // 1. Buscar matrículas do curso
    const { data: matriculas } = await supabaseClient
        .from('matriculas')
        .select('aluno_id, aluno_email')
        .eq('curso_id', cursoId);

    // 2. Buscar alunos em emails_autorizados por ID
    const { data: alunosPorId } = await supabaseClient
        .from('emails_autorizados')
        .select('*')
        .in('id', alunosIds);

    // 3. Buscar alunos em emails_autorizados por email
    const { data: alunosPorEmail } = await supabaseClient
        .from('emails_autorizados')
        .select('*')
        .in('email', alunosEmails);

    // 4. Renderizar dropdown
    const options = alunos.map(aluno => {
        const nome = aluno.nome || aluno.email;
        return `<option value="${aluno.id}">${nome} (${aluno.email})</option>`;
    });
}
```

**Status**: ✅ Usando emails_autorizados

---

## 📋 ESTRUTURA DE DADOS NECESSÁRIA

### **Tabelas no Supabase**

#### **1. emails_autorizados**
```sql
CREATE TABLE emails_autorizados (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    nome TEXT,
    autorizado BOOLEAN DEFAULT false,
    curso_id UUID REFERENCES cursos(id), -- Curso autorizado
    telefone TEXT,
    cidade TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### **2. matriculas**
```sql
CREATE TABLE matriculas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    aluno_id UUID NOT NULL REFERENCES auth.users(id),
    aluno_email TEXT, -- IMPORTANTE: Facilita queries
    curso_id UUID NOT NULL REFERENCES cursos(id),
    progresso INTEGER DEFAULT 0,
    data_matricula TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### **3. codigos_acesso**
```sql
CREATE TABLE codigos_acesso (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    codigo TEXT UNIQUE NOT NULL,
    curso_id UUID REFERENCES cursos(id),
    usado BOOLEAN DEFAULT false,
    user_id UUID REFERENCES auth.users(id),
    data_uso TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔗 FLUXO COMPLETO DO SISTEMA

```
┌─────────────────────────────────────────────────────────────┐
│ 1. ADMIN AUTORIZA ALUNO                                     │
│    - Admin insere em emails_autorizados                     │
│    - Define: email, nome, autorizado=true, curso_id         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. ADMIN CRIA CÓDIGO DE ACESSO (opcional)                   │
│    - Admin cria código em codigos_acesso                    │
│    - Associa código a um curso_id                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. ALUNO SE CADASTRA                                        │
│    - Valida código em codigos_acesso (se usar código)       │
│    - Valida email em emails_autorizados                     │
│    - Cria usuário em auth.users                             │
│    - Cria matrícula em matriculas (aluno_id + aluno_email)  │
│    - Cria perfil em profiles (opcional)                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. ALUNO FAZ LOGIN                                          │
│    - Autentica em auth.users                                │
│    - Busca matrículas WHERE aluno_id = user.id              │
│    - JOIN com cursos para obter dados do curso              │
│    - Mostra cursos, materiais e certificados                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. ADMIN VÊ DASHBOARD                                       │
│    - COUNT emails_autorizados (WHERE autorizado=true)       │
│    - COUNT cursos                                           │
│    - COUNT materiais                                        │
│    - COUNT matriculas                                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. ADMIN EMITE CERTIFICADO                                  │
│    - Seleciona curso                                        │
│    - Lista alunos de emails_autorizados matriculados        │
│    - Faz upload do PDF                                      │
│    - Salva em certificados (aluno_id + curso_id + path)     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. ALUNO VÊ CERTIFICADO                                     │
│    - SELECT certificados WHERE aluno_id = user.id           │
│    - JOIN com cursos para nome do curso                     │
│    - Download via signed URL                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 PASSOS PARA CONFIGURAR NO SUPABASE

### **Passo 1: Execute o SQL de Estrutura**

Execute no **SQL Editor** do Supabase:

```sql
-- SOLUCAO-AREA-ALUNO-REAL.sql
-- (já criado no projeto)
```

Este SQL irá:
- ✅ Adicionar coluna `curso_id` em `emails_autorizados`
- ✅ Adicionar coluna `aluno_email` em `matriculas`
- ✅ Criar índices para performance
- ✅ Atualizar `aluno_email` em matrículas existentes

### **Passo 2: Popular Dados de Teste (Opcional)**

Se não houver dados, execute:

```sql
-- Criar curso
INSERT INTO cursos (titulo, descricao, carga_horaria)
VALUES ('Curso de Inspeção Veicular', 'Curso completo', 40);

-- Autorizar email
INSERT INTO emails_autorizados (email, autorizado, curso_id, nome)
SELECT 'aluno@teste.com', true, c.id, 'Aluno Teste'
FROM cursos c WHERE c.titulo = 'Curso de Inspeção Veicular';

-- Criar código de acesso
INSERT INTO codigos_acesso (codigo, curso_id)
SELECT 'TESTE123', c.id
FROM cursos c WHERE c.titulo = 'Curso de Inspeção Veicular';
```

### **Passo 3: Testar o Fluxo**

1. **Acesse**: http://localhost:5174/area-aluno.html
2. **Clique em**: "Criar Conta"
3. **Preencha**:
   - Email: `aluno@teste.com`
   - Código: `TESTE123`
   - Senha: qualquer
   - Nome, telefone, cidade
4. **Clique**: "Criar Conta"
5. **Verifique console** (F12):
   ```
   ✅ Email autorizado validado
   ✅ Código validado
   ✅ Usuário criado: {id: "..."}
   📝 Criando matrículas para cursos: ["..."]
   ✅ Matrículas criadas com sucesso: [...]
   ```

6. **Faça login** com o email/senha criados
7. **Verifique console**:
   ```
   👤 Carregando dados para usuário: {id: "...", email: "aluno@teste.com"}
   🔍 Buscando matrículas do aluno...
   📋 Matrículas encontradas: [...]
   📊 Total de matrículas: 1
   ```

8. **Dashboard deve mostrar**:
   - Curso matriculado
   - Estatísticas reais
   - Sem dados fake

---

## 🔍 DIAGNÓSTICO DE PROBLEMAS

### **Problema 1: Dashboard do aluno mostra 0 cursos**

**Verificar no console**:
```
⚠️ Nenhuma matrícula encontrada para este usuário
```

**Causas possíveis**:
1. Email não está em `emails_autorizados` com `autorizado = true`
2. Matrícula não foi criada na tabela `matriculas`
3. `aluno_id` da matrícula não corresponde ao `user.id`

**Solução**:
```sql
-- Verificar se aluno está autorizado
SELECT * FROM emails_autorizados WHERE email = 'aluno@teste.com';

-- Verificar se tem matrícula
SELECT * FROM matriculas WHERE aluno_email = 'aluno@teste.com';

-- Criar matrícula manualmente se necessário
INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0
FROM auth.users u
CROSS JOIN emails_autorizados ea
WHERE u.email = 'aluno@teste.com'
AND ea.email = 'aluno@teste.com'
AND ea.autorizado = true;
```

---

### **Problema 2: Dashboard admin mostra 0**

**Verificar**:
```sql
-- Contar alunos autorizados
SELECT COUNT(*) FROM emails_autorizados WHERE autorizado = true;

-- Contar cursos
SELECT COUNT(*) FROM cursos;

-- Contar materiais
SELECT COUNT(*) FROM materiais;
```

**Se todos retornarem 0**, você precisa popular dados.

---

### **Problema 3: Certificados não listam alunos**

**Verificar no console do admin**:
```
🔍 Buscando alunos matriculados no curso: ...
📋 Matrículas encontradas: [...]
✅ Alunos encontrados em emails_autorizados: [...]
```

**Causas**:
1. Curso não tem matrículas
2. Alunos matriculados não estão em `emails_autorizados`

**Solução**:
```sql
-- Adicionar alunos matriculados em emails_autorizados
INSERT INTO emails_autorizados (email, nome, autorizado)
SELECT DISTINCT
    u.email,
    u.email,
    true
FROM matriculas m
JOIN auth.users u ON u.id = m.aluno_id
WHERE m.curso_id = 'CURSO_ID_AQUI'
ON CONFLICT (email) DO NOTHING;
```

---

## 📊 QUERIES ÚTEIS

### **Ver todos os dados de um aluno**
```sql
SELECT
    u.email as aluno_email,
    ea.autorizado,
    ea.curso_id as curso_autorizado,
    m.curso_id as curso_matriculado,
    c.titulo as curso_titulo,
    m.progresso
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE u.email = 'aluno@teste.com';
```

### **Ver alunos sem matrícula**
```sql
SELECT
    ea.email,
    ea.nome,
    ea.curso_id
FROM emails_autorizados ea
WHERE ea.autorizado = true
AND ea.email NOT IN (
    SELECT aluno_email FROM matriculas WHERE aluno_email IS NOT NULL
);
```

### **Criar matrículas para alunos autorizados sem matrícula**
```sql
INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0
FROM auth.users u
JOIN emails_autorizados ea ON ea.email = u.email
WHERE ea.autorizado = true
AND ea.curso_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM matriculas m
    WHERE m.aluno_id = u.id AND m.curso_id = ea.curso_id
);
```

---

## ✅ CHECKLIST FINAL

- [ ] Execute `SOLUCAO-AREA-ALUNO-REAL.sql` no Supabase
- [ ] Verifique se `emails_autorizados` tem coluna `curso_id`
- [ ] Verifique se `matriculas` tem coluna `aluno_email`
- [ ] Popule dados de teste (curso + email autorizado + código)
- [ ] Teste cadastro de novo aluno
- [ ] Verifique logs no console durante cadastro
- [ ] Faça login com aluno cadastrado
- [ ] Verifique logs no console durante login
- [ ] Confirme que dashboard mostra curso real
- [ ] Teste admin dashboard (estatísticas)
- [ ] Teste emissão de certificado (listar alunos)

---

## 🎯 RESUMO

**Sistema agora está 100% conectado com dados reais**:

✅ Dashboard Admin - queries corretas
✅ Área do Aluno - busca matrículas reais
✅ Matrícula automática com `aluno_email`
✅ Logs detalhados para debug
✅ Mensagens de erro úteis
✅ Certificados buscam de `emails_autorizados`

**Próximos passos**: Executar SQL e testar fluxo completo.
