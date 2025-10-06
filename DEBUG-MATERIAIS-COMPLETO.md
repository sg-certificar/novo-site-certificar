# 🐛 Debug Completo do Sistema de Materiais

## 📊 ANÁLISE DO FLUXO COMPLETO

### 1️⃣ ADMIN: Como Materiais São Salvos

**Arquivo:** `public/admin/script.js` (linhas 675-684)

**SQL executado pelo Admin:**
```javascript
await supabaseClient.from('materiais').insert({
    curso_id: cursoId,        // UUID do curso
    modulo: modulo,           // Ex: "Módulo 1"
    titulo: titulo,           // Ex: "Apostila Completa"
    tipo: getFileType(file.name), // Ex: "pdf"
    arquivo_path: filePath,   // Ex: "uuid-curso/modulo-1/timestamp_arquivo.pdf"
    tamanho: formatFileSize(file.size) // Ex: "2.5 MB"
});
```

**Storage Path:** `course-materials/{curso_id}/{modulo}/{timestamp}_arquivo.pdf`

**Exemplo real:**
```
curso_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
modulo: "Módulo 1"
titulo: "Apostila PDF"
tipo: "pdf"
arquivo_path: "a1b2c3d4-e5f6-7890-abcd-ef1234567890/Módulo 1/1234567890_apostila.pdf"
tamanho: "2.5 MB"
```

---

### 2️⃣ ÁREA DO ALUNO: Como Busca Materiais

**Arquivo:** `public/area-aluno.html` (linhas 1357-1407)

**Passo 1: Buscar Cursos Matriculados**
```javascript
// Linha 1313-1324
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
```

**Resultado esperado:**
```javascript
[
    {
        id: "matricula-uuid",
        aluno_id: "user-uuid",
        curso_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        progresso: 50,
        cursos: {
            id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            titulo: "Inspeção Veicular",
            carga_horaria: 40,
            descricao: "Curso completo..."
        }
    }
]
```

**Passo 2: Extrair IDs dos Cursos**
```javascript
// Linha 1366
const cursosIds = matriculas.map(m => m.curso_id);
// Resultado: ["a1b2c3d4-e5f6-7890-abcd-ef1234567890", "outro-uuid", ...]
```

**Passo 3: Buscar Materiais Desses Cursos**
```javascript
// Linha 1369-1374
const { data: materiais } = await supabaseClient
    .from('materiais')
    .select('*')
    .in('curso_id', cursosIds)
    .order('modulo', { ascending: true })
    .order('ordem', { ascending: true });
```

**SQL Equivalente:**
```sql
SELECT * FROM materiais
WHERE curso_id IN ('uuid-curso-1', 'uuid-curso-2', ...)
ORDER BY modulo ASC, ordem ASC;
```

---

### 3️⃣ DOWNLOAD: Como Funciona

**Arquivo:** `public/area-aluno.html` (linhas 1466-1504)

**Passo 1: Gerar URL Assinada**
```javascript
// Linha 1476-1479
const { data, error } = await supabaseClient
    .storage
    .from('course-materials')
    .createSignedUrl(storagePath, 60); // 60 segundos
```

**❌ PROBLEMA CRÍTICO AQUI:**
Na linha 1444, o código usa `material.storage_path`:
```javascript
onclick="downloadMaterial('${material.id}', '${material.storage_path}', '${material.titulo}')"
```

**MAS o admin salva como `arquivo_path`!**

---

## 🔍 DIAGNÓSTICO DOS PROBLEMAS

### ❌ Problema 1: Nome de Coluna Errado

**No Admin (script.js:667):**
```javascript
arquivo_path: filePath  // ✅ Salva como "arquivo_path"
```

**Na Área do Aluno (area-aluno.html:1444):**
```javascript
'${material.storage_path}'  // ❌ Tenta ler "storage_path"
```

**SOLUÇÃO:** Mudar linha 1444 para usar `arquivo_path`.

---

### ❌ Problema 2: Coluna "ordem" Não Existe

**Na Área do Aluno (line 1374):**
```javascript
.order('ordem', { ascending: true });
```

Mas a tabela `materiais` provavelmente **não tem coluna `ordem`**.

**SOLUÇÃO:** Remover `.order('ordem')` ou adicionar coluna na tabela.

---

### ❌ Problema 3: RLS Pode Estar Bloqueando

**Verificar se políticas RLS permitem:**
- ✅ Usuário autenticado pode SELECT em `materiais`
- ✅ Usuário autenticado pode SELECT em `storage.objects`
- ✅ URLs assinadas funcionam com bucket privado

---

## 🔧 SOLUÇÕES IMPLEMENTADAS

### Solução 1: Corrigir Nome da Coluna

**Editar `public/area-aluno.html` linha 1444:**

**ANTES:**
```javascript
onclick="downloadMaterial('${material.id}', '${material.storage_path}', '${material.titulo}')"
```

**DEPOIS:**
```javascript
onclick="downloadMaterial('${material.id}', '${material.arquivo_path}', '${material.titulo}')"
```

### Solução 2: Remover Order por "ordem"

**Editar `public/area-aluno.html` linha 1369-1374:**

**ANTES:**
```javascript
.order('modulo', { ascending: true })
.order('ordem', { ascending: true });
```

**DEPOIS:**
```javascript
.order('modulo', { ascending: true })
.order('created_at', { ascending: true });
```

### Solução 3: Adicionar Logs de Debug

**No Admin (após upload bem-sucedido):**
```javascript
console.log('📊 Material salvo:', {
    curso_id: cursoId,
    modulo: modulo,
    titulo: titulo,
    arquivo_path: filePath
});
```

**Na Área do Aluno (após buscar materiais):**
```javascript
console.log('📚 Materiais encontrados:', {
    total: materiais?.length,
    cursos_matriculados: cursosIds,
    materiais: materiais
});
```

**No Download:**
```javascript
console.log('⬇️ Tentando download:', {
    materialId: materialId,
    arquivo_path: storagePath,
    titulo: titulo
});
```

---

## 📋 CHECKLIST DE VERIFICAÇÃO

### ✅ Verificar Admin:

```javascript
// 1. Após fazer upload, verifique no console:
console.log('Upload info:', {
    curso_id: cursoId,
    arquivo_path: filePath
});

// 2. Verifique no Supabase Dashboard → Materiais:
SELECT id, curso_id, titulo, arquivo_path, modulo FROM materiais;
```

### ✅ Verificar Área do Aluno:

```javascript
// 1. Após login, verifique matrículas:
console.log('Matrículas:', matriculas);

// 2. Verifique IDs dos cursos:
console.log('Cursos IDs:', cursosIds);

// 3. Verifique materiais buscados:
console.log('Materiais:', materiais);
```

### ✅ Verificar Estrutura das Tabelas:

```sql
-- Verificar colunas da tabela materiais
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'materiais';

-- Deve ter:
-- - id (uuid)
-- - curso_id (uuid)
-- - titulo (text)
-- - modulo (text)
-- - tipo (text)
-- - arquivo_path (text) ← IMPORTANTE
-- - tamanho (text)
-- - created_at (timestamp)
```

---

## 🎯 FLUXO CORRETO ESPERADO

1. **Admin faz upload:**
   - Upload para Storage → `course-materials/{curso_id}/{modulo}/arquivo.pdf`
   - Salva na tabela → `arquivo_path` = caminho do Storage

2. **Aluno faz login:**
   - Sistema busca matrículas do aluno
   - Extrai `curso_id` de cada matrícula

3. **Sistema lista materiais:**
   - Busca materiais WHERE `curso_id` IN (cursos matriculados)
   - Agrupa por módulo
   - Renderiza na interface

4. **Aluno clica em download:**
   - Sistema pega `arquivo_path` do material
   - Gera URL assinada temporária (60 segundos)
   - Abre em nova aba

---

## 🚨 ERROS COMUNS E SOLUÇÕES

### Erro: "Nenhum material disponível"

**Possíveis causas:**
1. ❌ Aluno não está matriculado em nenhum curso
2. ❌ Não existem materiais para os cursos matriculados
3. ❌ `curso_id` na tabela materiais não bate com curso da matrícula

**Debug:**
```javascript
console.log('Cursos matriculados:', cursosIds);
console.log('Materiais encontrados:', materiais);
```

**Verificar no Supabase:**
```sql
-- Ver matrículas do aluno
SELECT * FROM matriculas WHERE aluno_id = 'user-uuid';

-- Ver materiais desses cursos
SELECT * FROM materiais WHERE curso_id IN ('curso-uuid-1', 'curso-uuid-2');
```

### Erro: "Erro ao preparar download"

**Possíveis causas:**
1. ❌ `arquivo_path` está NULL ou vazio
2. ❌ Arquivo não existe no Storage
3. ❌ RLS bloqueando acesso

**Debug:**
```javascript
console.log('Storage path:', storagePath);
console.log('Erro:', error);
```

**Verificar no Supabase Storage:**
- Dashboard → Storage → course-materials
- Verificar se arquivo existe no caminho

### Erro: "RLS policy violation"

**Solução:**
```sql
-- Verificar políticas
SELECT * FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';

-- Garantir que authenticated pode SELECT
CREATE POLICY "authenticated_download" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'course-materials');
```

---

## 📝 QUERIES SQL ÚTEIS

```sql
-- 1. Ver todos os materiais com curso relacionado
SELECT m.id, m.titulo, m.modulo, m.arquivo_path, c.titulo as curso_nome
FROM materiais m
LEFT JOIN cursos c ON c.id = m.curso_id;

-- 2. Ver matrículas com cursos
SELECT ma.id, ma.aluno_id, ma.progresso, c.titulo as curso_nome
FROM matriculas ma
LEFT JOIN cursos c ON c.id = ma.curso_id
WHERE ma.aluno_id = 'user-uuid';

-- 3. Ver materiais disponíveis para um aluno
SELECT m.*
FROM materiais m
INNER JOIN matriculas ma ON ma.curso_id = m.curso_id
WHERE ma.aluno_id = 'user-uuid';
```

---

## ✅ PRÓXIMOS PASSOS

1. ✅ Corrigir `storage_path` → `arquivo_path` na área do aluno
2. ✅ Remover `.order('ordem')` ou adicionar coluna
3. ✅ Adicionar logs de debug
4. ✅ Testar fluxo completo
5. ✅ Verificar RLS policies
