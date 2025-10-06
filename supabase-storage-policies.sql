-- ========================================
-- POLÍTICAS RLS PARA STORAGE
-- Bucket: course-materials
-- ========================================

-- 1. Remover políticas existentes (se houver)
DROP POLICY IF EXISTS "Permitir upload para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir download para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir listagem para usuários autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir deleção para usuários autenticados" ON storage.objects;

-- 2. POLÍTICA: Upload (INSERT) - Usuários autenticados podem fazer upload
CREATE POLICY "Permitir upload para usuários autenticados"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'course-materials'
);

-- 3. POLÍTICA: Download (SELECT) - Usuários autenticados podem fazer download
CREATE POLICY "Permitir download para usuários autenticados"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'course-materials'
);

-- 4. POLÍTICA: Listagem - Usuários autenticados podem listar arquivos
CREATE POLICY "Permitir listagem para usuários autenticados"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'course-materials'
);

-- 5. POLÍTICA: Deleção (DELETE) - Usuários autenticados podem deletar
CREATE POLICY "Permitir deleção para usuários autenticados"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'course-materials'
);

-- ========================================
-- VERIFICAR SE BUCKET EXISTE
-- ========================================
-- Se o bucket não existir, criar:
INSERT INTO storage.buckets (id, name, public)
VALUES ('course-materials', 'course-materials', false)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- ATIVAR RLS NO BUCKET
-- ========================================
UPDATE storage.buckets
SET public = false
WHERE id = 'course-materials';
