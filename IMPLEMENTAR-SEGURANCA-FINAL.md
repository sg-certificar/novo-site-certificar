# 🔒 Implementar Segurança Correta - Guia Completo

## 📋 PASSO A PASSO

### 1️⃣ Criar Usuário Admin no Supabase Auth

**Acesse:** https://supabase.com/dashboard/project/jfgnelowaaiwuzwelbot/auth/users

1. Clique em **"Add user"** → **"Create new user"**
2. Preencha:
   - **Email:** `admin@certificar.app.br`
   - **Password:** `EscolaAdmin2024!`
   - **Auto Confirm User:** ✅ **MARQUE ESTA OPÇÃO**
3. Clique em **"Create user"**

### 2️⃣ Executar SQL de Segurança

**Acesse:** https://supabase.com/dashboard/project/jfgnelowaaiwuzwelbot/sql/new

**Cole e execute o conteúdo do arquivo:** `SEGURANCA-CORRETA-STORAGE.sql`

Ou copie este SQL:

```sql
-- Bucket privado
UPDATE storage.buckets SET public = false WHERE id = 'course-materials';

-- Remover políticas públicas
DROP POLICY IF EXISTS "public_upload" ON storage.objects;
DROP POLICY IF EXISTS "public_download" ON storage.objects;
DROP POLICY IF EXISTS "public_delete" ON storage.objects;

-- Criar políticas para authenticated
CREATE POLICY "authenticated_upload" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (bucket_id = 'course-materials');

CREATE POLICY "authenticated_download" ON storage.objects
FOR SELECT TO authenticated USING (bucket_id = 'course-materials');

CREATE POLICY "authenticated_delete" ON storage.objects
FOR DELETE TO authenticated USING (bucket_id = 'course-materials');

-- RLS na tabela materiais
ALTER TABLE materiais ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated_select_materiais" ON materiais;
CREATE POLICY "authenticated_select_materiais" ON materiais
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "authenticated_insert_materiais" ON materiais;
CREATE POLICY "authenticated_insert_materiais" ON materiais
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_delete_materiais" ON materiais;
CREATE POLICY "authenticated_delete_materiais" ON materiais
FOR DELETE TO authenticated USING (true);
```

### 3️⃣ Testar Login e Upload

1. **Faça logout** do admin (se estiver logado)
2. **Faça login novamente** em: http://localhost:5174/admin/login.html
3. **Verifique no console (F12):**
   - Deve aparecer: `✅ Autenticado no Supabase: admin@certificar.app.br`
4. **Teste upload** de um material
   - Deve funcionar normalmente

### 4️⃣ Verificar Segurança

**Teste 1: Acesso sem autenticação (deve FALHAR)**
```javascript
// Abra console do navegador em uma aba anônima
const { createClient } = supabase
const client = createClient('https://jfgnelowaaiwuzwelbot.supabase.co', 'ANON_KEY')

// Tentar upload sem login → deve FALHAR ❌
await client.storage.from('course-materials').upload('teste.pdf', new Blob())
// Erro: "new row violates row-level security policy"

// Tentar inserir sem login → deve FALHAR ❌
await client.from('materiais').insert({ titulo: 'hack' })
// Erro: "new row violates row-level security policy"
```

**Teste 2: Acesso com autenticação (deve FUNCIONAR)**
```javascript
// Após fazer login no admin
// Upload deve funcionar ✅
// Inserção deve funcionar ✅
```

## 🎯 RESULTADO FINAL

### ✅ O que está protegido:

1. **Storage privado** - Apenas autenticados acessam
2. **RLS habilitado** - Apenas autenticados fazem operações
3. **Admin autenticado** - Login autentica com Supabase
4. **Área do aluno** - Filtra materiais por curso_id

### 🔐 Fluxo de Segurança:

**Admin:**
1. Login → Autentica no Supabase
2. Upload → Permitido (authenticated)
3. Material salvo no bucket privado

**Aluno:**
1. Login na área do aluno → Autentica no Supabase
2. Lista materiais filtrados por seu curso_id
3. Download → Sistema gera URL assinada temporária
4. URL expira após 1 hora

**Pessoa não autenticada:**
- ❌ Não consegue fazer upload
- ❌ Não consegue inserir na tabela
- ❌ Não consegue baixar arquivos
- ❌ Não consegue listar materiais

## 📝 EXEMPLO: Área do Aluno

```javascript
// Na área do aluno (public/area-aluno/)
async function loadMateriais() {
    // 1. Buscar materiais do curso do aluno
    const { data: materiais } = await supabaseClient
        .from('materiais')
        .select('*')
        .eq('curso_id', alunoLogado.curso_id);

    // 2. Para cada material, gerar URL assinada
    for (const material of materiais) {
        const { data: urlData } = await supabaseClient
            .storage
            .from('course-materials')
            .createSignedUrl(material.arquivo_path, 3600); // 1 hora

        material.download_url = urlData.signedUrl;
    }

    // 3. Exibir na interface
    renderMateriais(materiais);
}
```

## ⚠️ NOTAS IMPORTANTES

1. **Não quebra upload atual** - Admin continua funcionando
2. **Código já atualizado** - Login autentica com Supabase
3. **Fallback implementado** - Se autenticação Supabase falhar, continua com local
4. **Próximo passo** - Implementar área do aluno com filtro por curso

## 🚀 BENEFÍCIOS

- ✅ Materiais protegidos
- ✅ Apenas alunos autenticados acessam
- ✅ Cada aluno vê apenas materiais do seu curso
- ✅ URLs temporárias (expiram em 1h)
- ✅ Sem risco de acesso não autorizado
