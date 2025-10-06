-- ========================================
-- CORRIGIR - Preencher aluno_id na matrícula
-- ========================================

-- 1. VER DADOS ATUAIS DA MATRÍCULA
SELECT
    id,
    aluno_id,
    aluno_email,
    curso_id,
    progresso,
    created_at
FROM matriculas
WHERE aluno_email = 'vmanara@gmail.com';

-- 2. VER ID DO USUÁRIO
SELECT id, email FROM auth.users WHERE email = 'vmanara@gmail.com';

-- 3. ATUALIZAR MATRÍCULA COM aluno_id
UPDATE matriculas
SET aluno_id = (
    SELECT id FROM auth.users WHERE email = 'vmanara@gmail.com'
)
WHERE aluno_email = 'vmanara@gmail.com'
AND aluno_id IS NULL
RETURNING *;

-- 4. VERIFICAR SE CORRIGIU
SELECT
    m.id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    u.email as user_email,
    c.titulo as curso_titulo,
    CASE
        WHEN m.aluno_id IS NOT NULL THEN '✅ aluno_id PREENCHIDO'
        ELSE '❌ aluno_id VAZIO'
    END as status
FROM matriculas m
LEFT JOIN auth.users u ON u.id = m.aluno_id
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE m.aluno_email = 'vmanara@gmail.com';

-- 5. SE AINDA NÃO FUNCIONAR - RECRIAR MATRÍCULA DO ZERO
DELETE FROM matriculas WHERE aluno_email = 'vmanara@gmail.com';

INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0
FROM auth.users u
JOIN emails_autorizados ea ON ea.email = u.email
WHERE u.email = 'vmanara@gmail.com'
RETURNING *;
