-- ========================================
-- POPULAR MATRÍCULAS RETROATIVAMENTE
-- Para alunos que já existem mas não têm matrícula
-- ========================================

-- ========================================
-- 1. DIAGNÓSTICO - Ver alunos sem matrícula
-- ========================================

-- Listar usuários autorizados sem matrícula
SELECT
    u.id as user_id,
    u.email,
    ea.autorizado,
    ea.curso_id,
    c.titulo as curso_autorizado,
    CASE
        WHEN m.id IS NULL THEN 'SEM MATRÍCULA ❌'
        ELSE 'TEM MATRÍCULA ✅'
    END as status
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c ON c.id = ea.curso_id
LEFT JOIN matriculas m ON m.aluno_id = u.id AND m.curso_id = ea.curso_id
WHERE ea.autorizado = true
ORDER BY status, u.email;

-- ========================================
-- 2. CONTAR ALUNOS SEM MATRÍCULA
-- ========================================

SELECT
    COUNT(DISTINCT u.id) as total_alunos_autorizados,
    COUNT(DISTINCT m.aluno_id) as alunos_com_matricula,
    COUNT(DISTINCT u.id) - COUNT(DISTINCT m.aluno_id) as alunos_sem_matricula
FROM auth.users u
JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN matriculas m ON m.aluno_id = u.id
WHERE ea.autorizado = true;

-- ========================================
-- 3. CRIAR MATRÍCULAS PARA ALUNOS AUTORIZADOS
-- ========================================

-- IMPORTANTE: Este comando cria matrícula para TODOS os alunos
-- autorizados que ainda não têm matrícula

INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso, data_matricula)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0,
    NOW()
FROM auth.users u
JOIN emails_autorizados ea ON ea.email = u.email
WHERE ea.autorizado = true
AND ea.curso_id IS NOT NULL
-- Evitar duplicatas - só inserir se não existir
AND NOT EXISTS (
    SELECT 1
    FROM matriculas m
    WHERE m.aluno_id = u.id
    AND m.curso_id = ea.curso_id
)
RETURNING *;

-- ========================================
-- 4. CRIAR MATRÍCULA ESPECÍFICA PARA vmanara@gmail.com
-- ========================================

-- Use este comando se quiser criar matrícula APENAS para um aluno específico

INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso, data_matricula)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0,
    NOW()
FROM auth.users u
JOIN emails_autorizados ea ON ea.email = u.email
WHERE u.email = 'vmanara@gmail.com'
AND ea.autorizado = true
AND ea.curso_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM matriculas m
    WHERE m.aluno_id = u.id
    AND m.curso_id = ea.curso_id
)
RETURNING *;

-- ========================================
-- 5. VERIFICAR MATRÍCULAS CRIADAS
-- ========================================

-- Ver todas as matrículas com detalhes
SELECT
    m.id,
    m.aluno_email,
    u.email as user_email,
    c.titulo as curso,
    m.progresso,
    m.data_matricula,
    m.created_at
FROM matriculas m
LEFT JOIN auth.users u ON u.id = m.aluno_id
LEFT JOIN cursos c ON c.id = m.curso_id
ORDER BY m.created_at DESC;

-- ========================================
-- 6. VERIFICAR ESPECÍFICO PARA vmanara@gmail.com
-- ========================================

SELECT
    'auth.users' as tabela,
    u.id as user_id,
    u.email as user_email,
    u.created_at as user_criado_em
FROM auth.users u
WHERE u.email = 'vmanara@gmail.com'

UNION ALL

SELECT
    'emails_autorizados' as tabela,
    ea.id::text,
    ea.email,
    ea.created_at::text
FROM emails_autorizados ea
WHERE ea.email = 'vmanara@gmail.com'

UNION ALL

SELECT
    'matriculas' as tabela,
    m.id::text,
    m.aluno_email,
    m.created_at::text
FROM matriculas m
WHERE m.aluno_email = 'vmanara@gmail.com';

-- ========================================
-- 7. QUERY COMPLETA - Status de vmanara@gmail.com
-- ========================================

SELECT
    u.email as aluno,
    ea.autorizado as esta_autorizado,
    c1.titulo as curso_autorizado,
    CASE WHEN m.id IS NOT NULL THEN '✅' ELSE '❌' END as tem_matricula,
    c2.titulo as curso_matriculado,
    m.progresso,
    m.data_matricula
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c1 ON c1.id = ea.curso_id
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN cursos c2 ON c2.id = m.curso_id
WHERE u.email = 'vmanara@gmail.com';

-- ========================================
-- 8. ATUALIZAR aluno_email EM MATRÍCULAS EXISTENTES
-- ========================================

-- Se matrículas já existem mas sem aluno_email, preencher
UPDATE matriculas m
SET aluno_email = u.email
FROM auth.users u
WHERE m.aluno_id = u.id
AND (m.aluno_email IS NULL OR m.aluno_email = '')
RETURNING m.id, m.aluno_email, m.curso_id;

-- ========================================
-- 9. GARANTIR QUE emails_autorizados TEM curso_id
-- ========================================

-- Ver emails autorizados sem curso
SELECT
    email,
    nome,
    autorizado,
    curso_id,
    CASE
        WHEN curso_id IS NULL THEN 'PRECISA ASSOCIAR CURSO ⚠️'
        ELSE 'OK ✅'
    END as status
FROM emails_autorizados
WHERE autorizado = true;

-- Associar curso manualmente (exemplo com Curso de Piloto)
UPDATE emails_autorizados
SET curso_id = (
    SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1
)
WHERE email = 'vmanara@gmail.com'
AND curso_id IS NULL;

-- ========================================
-- 10. ESTATÍSTICAS FINAIS
-- ========================================

SELECT
    'Total de Alunos Autorizados' as metrica,
    COUNT(*)::text as valor
FROM emails_autorizados
WHERE autorizado = true

UNION ALL

SELECT
    'Alunos com Curso Associado',
    COUNT(*)::text
FROM emails_autorizados
WHERE autorizado = true AND curso_id IS NOT NULL

UNION ALL

SELECT
    'Total de Matrículas',
    COUNT(*)::text
FROM matriculas

UNION ALL

SELECT
    'Matrículas com Email Preenchido',
    COUNT(*)::text
FROM matriculas
WHERE aluno_email IS NOT NULL

UNION ALL

SELECT
    'Total de Cursos',
    COUNT(*)::text
FROM cursos

UNION ALL

SELECT
    'Total de Materiais',
    COUNT(*)::text
FROM materiais;

-- ========================================
-- ORDEM DE EXECUÇÃO RECOMENDADA
-- ========================================

/*
1. Execute seção 1 (DIAGNÓSTICO) para ver alunos sem matrícula
2. Execute seção 9 para garantir que emails_autorizados tem curso_id
3. Execute seção 3 para criar matrículas retroativamente
   OU
   Execute seção 4 para criar matrícula apenas para vmanara@gmail.com
4. Execute seção 8 para preencher aluno_email em matrículas antigas
5. Execute seção 7 para verificar status do vmanara@gmail.com
6. Execute seção 10 para ver estatísticas finais

RESULTADO ESPERADO:
✅ vmanara@gmail.com está em emails_autorizados com autorizado=true
✅ emails_autorizados.curso_id aponta para 'Curso de Piloto'
✅ Existe matrícula em matriculas com aluno_id + curso_id
✅ Quando vmanara fizer login, verá 'Curso de Piloto' automaticamente
*/
