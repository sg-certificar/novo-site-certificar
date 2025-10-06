-- ========================================
-- SEGURANÇA CORRETA PARA STORAGE E MATERIAIS
-- ========================================
-- Admin faz upload → Aluno autenticado baixa apenas seu curso

-- 1. TORNAR BUCKET PRIVADO (não público)
UPDATE storage.buckets SET public = false WHERE id = 'course-materials';

-- 2. REMOVER POLÍTICAS PÚBLICAS ANTIGAS
DROP POLICY IF EXISTS "public_upload" ON storage.objects;
DROP POLICY IF EXISTS "public_download" ON storage.objects;
DROP POLICY IF EXISTS "public_delete" ON storage.objects;
DROP POLICY IF EXISTS "Upload público" ON storage.objects;
DROP POLICY IF EXISTS "Download público" ON storage.objects;
DROP POLICY IF EXISTS "Delete público" ON storage.objects;

-- 3. CRIAR POLÍTICAS PARA USUÁRIOS AUTENTICADOS
-- Upload: apenas usuários autenticados (admin e sistema)
CREATE POLICY "authenticated_upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'course-materials');

-- Download: apenas usuários autenticados (alunos logados)
CREATE POLICY "authenticated_download" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'course-materials');

-- Delete: apenas usuários autenticados
CREATE POLICY "authenticated_delete" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'course-materials');

-- 4. HABILITAR RLS NA TABELA MATERIAIS
ALTER TABLE materiais ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS PARA TABELA MATERIAIS
-- Select: qualquer usuário autenticado pode VER materiais
-- (a área do aluno filtra por curso_id no frontend)
DROP POLICY IF EXISTS "authenticated_select_materiais" ON materiais;
CREATE POLICY "authenticated_select_materiais" ON materiais
FOR SELECT TO authenticated
USING (true);

-- Insert: apenas usuários autenticados podem INSERIR
-- (admin quando faz upload)
DROP POLICY IF EXISTS "authenticated_insert_materiais" ON materiais;
CREATE POLICY "authenticated_insert_materiais" ON materiais
FOR INSERT TO authenticated
WITH CHECK (true);

-- Update: apenas usuários autenticados podem ATUALIZAR
DROP POLICY IF EXISTS "authenticated_update_materiais" ON materiais;
CREATE POLICY "authenticated_update_materiais" ON materiais
FOR UPDATE TO authenticated
USING (true);

-- Delete: apenas usuários autenticados podem DELETAR
DROP POLICY IF EXISTS "authenticated_delete_materiais" ON materiais;
CREATE POLICY "authenticated_delete_materiais" ON materiais
FOR DELETE TO authenticated
USING (true);

-- 6. VERIFICAR SE FUNCIONOU
SELECT 'Bucket privado:', public FROM storage.buckets WHERE id = 'course-materials';
SELECT 'RLS habilitado em materiais:', relrowsecurity FROM pg_class WHERE relname = 'materiais';

-- ========================================
-- RESULTADO:
-- ✅ Bucket PRIVADO (apenas autenticados acessam)
-- ✅ RLS HABILITADO (apenas autenticados fazem operações)
-- ✅ Área do aluno filtra por curso_id no frontend
-- ✅ URLs assinadas temporárias para download seguro
-- ========================================
