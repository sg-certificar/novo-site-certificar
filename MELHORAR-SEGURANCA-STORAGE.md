# 🔒 Melhorar Segurança do Storage

## ⚠️ SITUAÇÃO ATUAL (INSEGURA)

- ✅ Upload funcionando
- ❌ Bucket PÚBLICO (qualquer pessoa pode fazer upload/download)
- ❌ Tabela materiais SEM RLS (qualquer pessoa pode inserir registros)
- ❌ Admin sem autenticação no Supabase

## 🎯 SOLUÇÕES DE SEGURANÇA

### OPÇÃO 1: Segurança Média (Recomendada para começar)

**Criar usuário admin no Supabase Auth:**

```sql
-- No Supabase Dashboard → Authentication → Users → Add user
Email: admin@certificar.app.br
Password: EscolaAdmin2024!
Auto Confirm: ✅ SIM
```

**Habilitar RLS com políticas de autenticação:**

```sql
-- 1. Tornar bucket PRIVADO
UPDATE storage.buckets SET public = false WHERE id = 'course-materials';

-- 2. Habilitar RLS na tabela materiais
ALTER TABLE materiais ENABLE ROW LEVEL SECURITY;

-- 3. Políticas: apenas usuários autenticados
DROP POLICY IF EXISTS "public_upload" ON storage.objects;
DROP POLICY IF EXISTS "public_download" ON storage.objects;

CREATE POLICY "authenticated_upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'course-materials');

CREATE POLICY "authenticated_download" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'course-materials');

CREATE POLICY "authenticated_delete" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'course-materials');

-- 4. Políticas para tabela materiais
CREATE POLICY "authenticated_insert_materiais" ON materiais
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "authenticated_select_materiais" ON materiais
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "authenticated_delete_materiais" ON materiais
FOR DELETE TO authenticated
USING (true);
```

**Atualizar código do admin:**

```javascript
// No login (handleLogin), já temos autenticação com Supabase
// Basta descomentar no script.js:

async function handleLogin(event) {
    // ... código existente ...

    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
        // AUTENTICAR COM SUPABASE (adicionar de volta)
        const { data: authData, error: authError } = await supabaseClient.auth.signInWithPassword({
            email: ADMIN_EMAIL,
            password: ADMIN_PASSWORD
        });

        if (authError) {
            throw new Error('Erro ao autenticar com Supabase');
        }

        // ... resto do código ...
    }
}
```

### OPÇÃO 2: Segurança Alta (Para produção)

**RLS com roles específicas:**

```sql
-- 1. Criar role admin customizada
-- (Requer configuração avançada no Supabase)

-- 2. Políticas baseadas em role
CREATE POLICY "admin_only_upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'course-materials' AND
    auth.jwt() ->> 'email' = 'admin@certificar.app.br'
);

-- 3. Políticas para materiais apenas para admin
CREATE POLICY "admin_only_insert_materiais" ON materiais
FOR INSERT TO authenticated
WITH CHECK (auth.jwt() ->> 'email' = 'admin@certificar.app.br');
```

### OPÇÃO 3: Segurança Máxima (Enterprise)

**Backend com Edge Functions:**

```typescript
// supabase/functions/upload-material/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Verificar autenticação
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 })
  }

  // Verificar se é admin
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
  const { data: user } = await supabase.auth.getUser(authHeader)

  if (user.email !== 'admin@certificar.app.br') {
    return new Response('Forbidden', { status: 403 })
  }

  // Processar upload com validações
  // - Verificar tipo de arquivo
  // - Limitar tamanho
  // - Validar curso_id existe
  // - Upload para Storage
  // - Inserir na tabela materiais

  return new Response(JSON.stringify({ success: true }))
})
```

## 📋 RECOMENDAÇÃO IMEDIATA

**Para melhorar rapidamente SEM quebrar o upload:**

1. **Criar usuário admin no Supabase** (via Dashboard)
2. **Reativar autenticação no login** (código já existe, basta descomentar)
3. **Manter bucket público TEMPORARIAMENTE** (para não quebrar)
4. **Depois implementar OPÇÃO 1** quando tiver tempo

## 🔍 VERIFICAR QUEM PODE ACESSAR

**Teste atual:**
```javascript
// Qualquer pessoa pode fazer isso no console do navegador:
const { createClient } = supabase
const client = createClient('https://jfgnelowaaiwuzwelbot.supabase.co', 'ANON_KEY')

// Upload sem autenticação (funciona agora!)
await client.storage.from('course-materials').upload('teste.pdf', file)

// Inserir material sem autenticação (funciona agora!)
await client.from('materiais').insert({ titulo: 'hack' })
```

**Depois da OPÇÃO 1:**
```javascript
// Upload sem autenticação → BLOQUEADO ❌
// Inserir sem autenticação → BLOQUEADO ❌
// Apenas admin autenticado → PERMITIDO ✅
```

## ⚡ AÇÃO RÁPIDA

Execute este SQL agora para melhorar um pouco:

```sql
-- Validação básica: não permitir campos vazios
ALTER TABLE materiais
  ALTER COLUMN titulo SET NOT NULL,
  ALTER COLUMN curso_id SET NOT NULL,
  ALTER COLUMN modulo SET NOT NULL;

-- Limitar tipos de arquivo
CREATE POLICY "only_pdf_uploads" ON storage.objects
FOR INSERT TO public
WITH CHECK (
    bucket_id = 'course-materials' AND
    (storage.extension(name) = 'pdf' OR
     storage.extension(name) = 'mp4' OR
     storage.extension(name) = 'docx')
);
```

Qual opção você quer implementar primeiro?
