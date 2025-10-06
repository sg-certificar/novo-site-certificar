# 🔧 Instruções para Corrigir RLS no Storage

## ❌ PROBLEMA
Upload de materiais falhando com erro:
```
new row violates row-level security policy
```

## ✅ SOLUÇÃO IMPLEMENTADA

### 1. **Execute o SQL no Supabase**

Acesse: https://supabase.com/dashboard/project/jfgnelowaaiwuzwelbot/sql/new

Cole e execute o conteúdo do arquivo `supabase-storage-policies.sql`

### 2. **O que o SQL faz:**

✅ Remove políticas antigas (se existirem)
✅ Cria políticas RLS para bucket `course-materials`:
   - **INSERT**: Permite upload para usuários autenticados
   - **SELECT**: Permite download/listagem para usuários autenticados
   - **DELETE**: Permite deleção para usuários autenticados

✅ Garante que o bucket existe
✅ Configura bucket como privado (public = false)

### 3. **Código Admin Atualizado**

O arquivo `public/admin/script.js` foi atualizado para:
- ✅ **Autenticar com Supabase no login** (handleLogin)
- ✅ **Manter sessão autenticada** durante uso do admin
- ✅ **Verificar sessão** antes de fazer upload
- ✅ Logs detalhados para debug
- ✅ Melhor tratamento de erros

**IMPORTANTE:** Agora o admin autentica no Supabase ao fazer login, não apenas localmente!

### 4. **Estrutura de Pastas no Storage**

```
course-materials/
├── {curso_id}/
│   ├── {modulo}/
│   │   ├── arquivo1.pdf
│   │   ├── arquivo2.pdf
```

## 🧪 TESTE

**⚠️ IMPORTANTE: Faça logout e login novamente para autenticar no Supabase!**

1. **Acesse:** http://localhost:5174/admin/login.html
2. **Faça login** com `admin@certificar.app.br`
   - ✅ No console deve aparecer: **"Autenticado no Supabase: admin@certificar.app.br"**
   - Se não aparecer, a autenticação falhou
3. **Vá em "Gestão de Materiais"**
4. **Faça upload de um PDF:**
   - Selecione curso
   - Digite módulo (ex: "Módulo 1")
   - Digite título
   - Selecione arquivo PDF
   - Clique em "Enviar Material"

5. **Verifique no console do navegador (F12):**
   - 📤 Fazendo upload para: {curso_id}/{modulo}/{timestamp}_arquivo.pdf
   - ✅ Upload concluído!

6. **Verifique na tabela:**
   - Material aparece listado
   - Storage path correto

## 🔍 TROUBLESHOOTING

### Se continuar dando erro de RLS:

1. **Verificar se as políticas foram criadas:**
   ```sql
   SELECT * FROM pg_policies
   WHERE schemaname = 'storage'
   AND tablename = 'objects';
   ```

2. **Verificar se bucket existe:**
   ```sql
   SELECT * FROM storage.buckets
   WHERE id = 'course-materials';
   ```

3. **Verificar autenticação:**
   - Abra DevTools → Console
   - Deve aparecer: "✅ Autenticado com sucesso: admin@certificar.app.br"

### Se o erro persistir:

Alternativa: Tornar bucket público temporariamente:
```sql
UPDATE storage.buckets
SET public = true
WHERE id = 'course-materials';
```

**⚠️ Não recomendado para produção!**

## 📋 CHECKLIST

- [ ] Executar SQL no Supabase Dashboard
- [ ] Código admin já atualizado ✅
- [ ] Testar upload de PDF
- [ ] Verificar material na listagem
- [ ] Confirmar arquivo no Storage do Supabase
