-- ========================================
-- PREENCHER user_id NA MATRÍCULA
-- ========================================

-- A tabela matriculas tem DUAS colunas: user_id e aluno_id
-- Precisamos preencher ambas

-- 1. ATUALIZAR user_id = aluno_id
UPDATE matriculas
SET user_id = aluno_id
WHERE aluno_email = 'vmanara@gmail.com'
RETURNING *;

-- 2. VERIFICAR SE CORRIGIU
SELECT
    id,
    user_id,
    aluno_id,
    aluno_email,
    curso_id,
    CASE
        WHEN user_id IS NOT NULL AND aluno_id IS NOT NULL THEN '✅ AMBOS PREENCHIDOS'
        WHEN user_id IS NULL THEN '❌ user_id VAZIO'
        WHEN aluno_id IS NULL THEN '❌ aluno_id VAZIO'
    END as status
FROM matriculas
WHERE aluno_email = 'vmanara@gmail.com';

-- 3. ATUALIZAR TODAS AS MATRÍCULAS (não só vmanara)
UPDATE matriculas
SET user_id = aluno_id
WHERE user_id IS NULL
AND aluno_id IS NOT NULL
RETURNING aluno_email, user_id, aluno_id;
