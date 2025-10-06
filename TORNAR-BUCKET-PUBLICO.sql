-- ========================================
-- SOLUÇÃO SIMPLES: BUCKET PÚBLICO
-- ========================================
-- Execute este SQL no Supabase para permitir uploads sem autenticação

-- 1. Tornar bucket course-materials PÚBLICO
UPDATE storage.buckets
SET public = true
WHERE id = 'course-materials';

-- 2. Remover TODAS as políticas RLS (não precisamos com bucket público)
DROP POLICY IF EXISTS "Permitir upload para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir download para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir listagem para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir deleção para usuários autenticados" ON storage.objects;

-- 3. Criar políticas PÚBLICAS (qualquer pessoa pode fazer upload/download)
CREATE POLICY "Upload público"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'course-materials');

CREATE POLICY "Download público"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course-materials');

CREATE POLICY "Deletar público"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'course-materials');

-- 4. Verificar se funcionou
SELECT id, name, public FROM storage.buckets WHERE id = 'course-materials';
-- Deve retornar: public = true

-- PRONTO! Agora o upload funciona sem autenticação
