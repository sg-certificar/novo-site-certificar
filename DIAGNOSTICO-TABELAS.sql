-- ========================================
-- DIAGNÓSTICO COMPLETO DAS TABELAS
-- ========================================

-- 1. VERIFICAR ESTRUTURA DE emails_autorizados
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'emails_autorizados'
ORDER BY ordinal_position;

-- 2. VERIFICAR ESTRUTURA DE matriculas
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'matriculas'
ORDER BY ordinal_position;

-- 3. VERIFICAR ESTRUTURA DE codigos_acesso
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'codigos_acesso'
ORDER BY ordinal_position;

-- 4. LISTAR DADOS DE emails_autorizados
SELECT * FROM emails_autorizados LIMIT 10;

-- 5. LISTAR DADOS DE matriculas
SELECT
    m.id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    m.progresso,
    c.titulo as curso_titulo
FROM matriculas m
LEFT JOIN cursos c ON c.id = m.curso_id
LIMIT 10;

-- 6. LISTAR CÓDIGOS DE ACESSO
SELECT
    codigo,
    curso_id,
    usado,
    user_id,
    data_uso
FROM codigos_acesso
LIMIT 10;

-- 7. CONTAR REGISTROS
SELECT
    'emails_autorizados' as tabela,
    COUNT(*) as total,
    COUNT(CASE WHEN autorizado = true THEN 1 END) as autorizados
FROM emails_autorizados
UNION ALL
SELECT 'matriculas', COUNT(*), COUNT(*) FROM matriculas
UNION ALL
SELECT 'cursos', COUNT(*), COUNT(*) FROM cursos
UNION ALL
SELECT 'materiais', COUNT(*), COUNT(*) FROM materiais
UNION ALL
SELECT 'certificados', COUNT(*), COUNT(*) FROM certificados
UNION ALL
SELECT 'codigos_acesso', COUNT(*), COUNT(CASE WHEN usado = true THEN 1 END) FROM codigos_acesso;

-- 8. VERIFICAR RELACIONAMENTOS
-- Matrículas sem curso
SELECT COUNT(*) as matriculas_sem_curso
FROM matriculas
WHERE curso_id NOT IN (SELECT id FROM cursos);

-- Matrículas sem aluno em auth.users
SELECT COUNT(*) as matriculas_sem_user
FROM matriculas
WHERE aluno_id NOT IN (SELECT id FROM auth.users);

-- 9. VERIFICAR SE EXISTE TABELA profiles
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_name = 'profiles'
) as profiles_existe;

-- 10. SE profiles EXISTIR, verificar estrutura
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;
