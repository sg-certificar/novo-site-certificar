-- ========================================
-- SQL FINAL SIMPLIFICADO - EXECUTAR NO SUPABASE
-- ========================================

-- 1. Adicionar coluna tamanho se não existir
ALTER TABLE materiais ADD COLUMN IF NOT EXISTS tamanho TEXT;

-- 2. DESABILITAR RLS na tabela materiais (solução mais simples)
ALTER TABLE materiais DISABLE ROW LEVEL SECURITY;

-- 3. Tornar bucket público
UPDATE storage.buckets SET public = true WHERE id = 'course-materials';

-- 4. Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Upload público" ON storage.objects;
DROP POLICY IF EXISTS "Download público" ON storage.objects;
DROP POLICY IF EXISTS "Delete público" ON storage.objects;
DROP POLICY IF EXISTS "Permitir upload para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir download para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir listagem para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir deleção para usuários autenticados" ON storage.objects;

-- 5. Criar políticas públicas novas
CREATE POLICY "public_upload" ON storage.objects
FOR INSERT TO public WITH CHECK (bucket_id = 'course-materials');

CREATE POLICY "public_download" ON storage.objects
FOR SELECT TO public USING (bucket_id = 'course-materials');

CREATE POLICY "public_delete" ON storage.objects
FOR DELETE TO public USING (bucket_id = 'course-materials');

-- PRONTO! Agora teste o upload
