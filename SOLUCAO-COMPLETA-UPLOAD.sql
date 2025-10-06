-- ========================================
-- SOLUÇÃO COMPLETA PARA UPLOAD FUNCIONAR
-- ========================================

-- 1. ADICIONAR COLUNAS FALTANTES NA TABELA materiais
ALTER TABLE materiais ADD COLUMN IF NOT EXISTS storage_path TEXT;
ALTER TABLE materiais ADD COLUMN IF NOT EXISTS tamanho TEXT;

-- 2. DESABILITAR RLS NA TABELA materiais (SOLUÇÃO SIMPLES)
ALTER TABLE materiais DISABLE ROW LEVEL SECURITY;

-- OU (se preferir manter RLS com políticas públicas):
-- ALTER TABLE materiais ENABLE ROW LEVEL SECURITY;
-- DROP POLICY IF EXISTS "Permitir insert público" ON materiais;
-- CREATE POLICY "Permitir insert público" ON materiais FOR INSERT TO public WITH CHECK (true);
-- CREATE POLICY "Permitir select público" ON materiais FOR SELECT TO public USING (true);
-- CREATE POLICY "Permitir delete público" ON materiais FOR DELETE TO public USING (true);

-- 3. TORNAR BUCKET PÚBLICO
UPDATE storage.buckets SET public = true WHERE id = 'course-materials';

-- 4. REMOVER POLÍTICAS ANTIGAS DO STORAGE
DROP POLICY IF EXISTS "Permitir upload para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir download para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir listagem para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir deleção para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Upload público" ON storage.objects;
DROP POLICY IF EXISTS "Download público" ON storage.objects;
DROP POLICY IF EXISTS "Deletar público" ON storage.objects;

-- 5. CRIAR POLÍTICAS PÚBLICAS PARA STORAGE
CREATE POLICY "Upload público" ON storage.objects
FOR INSERT TO public
WITH CHECK (bucket_id = 'course-materials');

CREATE POLICY "Download público" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'course-materials');

CREATE POLICY "Delete público" ON storage.objects
FOR DELETE TO public
USING (bucket_id = 'course-materials');

-- 6. VERIFICAR SE FUNCIONOU
SELECT 'Bucket público:', public FROM storage.buckets WHERE id = 'course-materials';
SELECT 'Colunas da tabela materiais:' as info;
SELECT column_name FROM information_schema.columns WHERE table_name = 'materiais';
SELECT 'RLS desabilitado na tabela materiais:' as info;
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'materiais';
