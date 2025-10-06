-- ========================================
-- QUICK FIX - Executar na ordem
-- ========================================

-- ========================================
-- 1. VER ESTRUTURA REAL
-- ========================================

-- Mostrar TODAS as colunas de matriculas
SELECT column_name FROM information_schema.columns
WHERE table_name = 'matriculas'
ORDER BY ordinal_position;

-- Mostrar TODAS as colunas de emails_autorizados
SELECT column_name FROM information_schema.columns
WHERE table_name = 'emails_autorizados'
ORDER BY ordinal_position;

-- ========================================
-- 2. VER DADOS EXISTENTES
-- ========================================

SELECT * FROM auth.users WHERE email = 'vmanara@gmail.com';
SELECT * FROM emails_autorizados WHERE email = 'vmanara@gmail.com';
SELECT * FROM cursos LIMIT 5;
SELECT * FROM matriculas LIMIT 5;
SELECT * FROM materiais LIMIT 5;

-- ========================================
-- 3. ADICIONAR COLUNAS FALTANTES
-- ========================================

-- Adicionar aluno_id em matriculas (pode já existir - vai ignorar se sim)
ALTER TABLE matriculas ADD COLUMN IF NOT EXISTS aluno_id UUID;

-- Adicionar aluno_email em matriculas
ALTER TABLE matriculas ADD COLUMN IF NOT EXISTS aluno_email TEXT;

-- Adicionar curso_id em emails_autorizados
ALTER TABLE matriculas ADD COLUMN IF NOT EXISTS curso_id UUID;

-- Adicionar curso_id em emails_autorizados
ALTER TABLE emails_autorizados ADD COLUMN IF NOT EXISTS curso_id UUID;

-- Adicionar progresso em matriculas
ALTER TABLE matriculas ADD COLUMN IF NOT EXISTS progresso INTEGER DEFAULT 0;

-- ========================================
-- 4. CRIAR CURSO (se não existir)
-- ========================================

INSERT INTO cursos (titulo, descricao, carga_horaria)
VALUES ('Curso de Piloto', 'Curso completo de pilotagem de aeronaves', 40)
ON CONFLICT DO NOTHING
RETURNING id, titulo;

-- ========================================
-- 5. AUTORIZAR EMAIL
-- ========================================

INSERT INTO emails_autorizados (email, autorizado, curso_id)
VALUES (
    'vmanara@gmail.com',
    true,
    (SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1)
)
ON CONFLICT (email) DO UPDATE
SET
    autorizado = true,
    curso_id = (SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1)
RETURNING *;

-- ========================================
-- 6. CRIAR MATRÍCULA
-- ========================================

INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0
FROM auth.users u
JOIN emails_autorizados ea ON ea.email = u.email
WHERE u.email = 'vmanara@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM matriculas m
    WHERE (m.aluno_id = u.id OR m.aluno_email = u.email)
    AND m.curso_id = ea.curso_id
)
RETURNING *;

-- ========================================
-- 7. VERIFICAR RESULTADO
-- ========================================

-- Ver tudo sobre vmanara@gmail.com
SELECT
    u.email as usuario,
    ea.autorizado as esta_autorizado,
    c1.titulo as curso_autorizado,
    m.aluno_id as matricula_aluno_id,
    m.aluno_email as matricula_email,
    c2.titulo as curso_matriculado,
    m.progresso
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c1 ON c1.id = ea.curso_id
LEFT JOIN matriculas m ON (m.aluno_id = u.id OR m.aluno_email = u.email)
LEFT JOIN cursos c2 ON c2.id = m.curso_id
WHERE u.email = 'vmanara@gmail.com';

-- ========================================
-- 8. SE DER ERRO "column does not have a default value"
-- ========================================

-- Significa que matriculas tem colunas obrigatórias
-- Ver quais são:
SELECT column_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'matriculas'
AND is_nullable = 'NO'
AND column_default IS NULL;

-- Depois ajustar o INSERT para incluir essas colunas
