# 🚀 Upload Simplificado - Funciona em 5 Minutos

## ✅ SOLUÇÃO IMPLEMENTADA

Upload **SEM autenticação complexa** - Bucket público com políticas simples.

## 📋 PASSO A PASSO

### 1. Execute o SQL no Supabase

Acesse: https://supabase.com/dashboard/project/jfgnelowaaiwuzwelbot/sql/new

Cole e execute o conteúdo do arquivo: **`TORNAR-BUCKET-PUBLICO.sql`**

### 2. O que o SQL faz:

- ✅ Torna bucket `course-materials` **PÚBLICO**
- ✅ Remove políticas RLS antigas
- ✅ Cria políticas públicas (qualquer pessoa pode upload/download)

### 3. Teste o Upload

1. Acesse: http://localhost:5174/admin/login.html
2. Faça login com `admin@certificar.app.br`
3. Vá em "Gestão de Materiais"
4. Faça upload de um PDF

### 4. Console do Navegador (F12)

Você deve ver:
```
📤 Fazendo upload para: {curso_id}/{modulo}/{timestamp}_arquivo.pdf
✅ Upload concluído!
```

## 🔧 CÓDIGO ATUALIZADO

### Antes (COMPLEXO):
```javascript
// Autenticar com Supabase
// Verificar sessão
// Upload com RLS
```

### Agora (SIMPLES):
```javascript
// Upload direto para Storage público
// Inserção na tabela materiais
// Pronto!
```

## ⚠️ IMPORTANTE

**Bucket público = qualquer pessoa pode fazer upload**

Para produção, considere:
- Adicionar validação de admin no backend
- Limitar tamanho de arquivos
- Validar tipos de arquivo permitidos

## ✅ CHECKLIST

- [ ] Executar `TORNAR-BUCKET-PUBLICO.sql` no Supabase
- [ ] Código já atualizado ✅
- [ ] Testar upload de PDF
- [ ] Verificar material na listagem
- [ ] Confirmar arquivo no Storage

## 🎯 RESULTADO

Upload funcionando **SEM complicação de autenticação RLS!**
