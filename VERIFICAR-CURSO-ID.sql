-- ========================================
-- VERIFICAR - Curso ID e JOIN
-- ========================================

-- 1. VER CURSOS EXISTENTES E SEUS IDs
SELECT
    id,
    titulo,
    pg_typeof(id) as tipo_id
FROM cursos;

-- 2. VER MATRÍCULA COMPLETA
SELECT
    m.id as matricula_id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    pg_typeof(m.curso_id) as tipo_curso_id
FROM matriculas m
WHERE m.aluno_email = 'vmanara@gmail.com';

-- 3. TESTAR JOIN MANUALMENTE
SELECT
    m.id as matricula_id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    c.id as curso_real_id,
    c.titulo as curso_titulo,
    CASE
        WHEN c.id IS NOT NULL THEN '✅ JOIN FUNCIONOU'
        ELSE '❌ JOIN FALHOU'
    END as status_join
FROM matriculas m
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE m.aluno_email = 'vmanara@gmail.com';

-- 4. SIMULAR QUERY DO FRONTEND
-- Esta é exatamente a query que o frontend executa
SELECT
    m.*,
    jsonb_build_object(
        'id', c.id,
        'titulo', c.titulo,
        'carga_horaria', c.carga_horaria,
        'descricao', c.descricao
    ) as cursos
FROM matriculas m
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE m.aluno_id = '82f61a11-415e-468f-810d-45c812893ff9';
-- ^ Este é o aluno_id do vmanara

-- 5. SE curso_id ESTIVER ERRADO, CORRIGIR
UPDATE matriculas
SET curso_id = (SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1)
WHERE aluno_email = 'vmanara@gmail.com'
RETURNING *;
