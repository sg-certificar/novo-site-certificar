-- ========================================
-- DIAGNÓSTICO URGENTE - Por que área do aluno não mostra cursos?
-- ========================================

-- ========================================
-- 1. VERIFICAR USUÁRIO LOGADO
-- ========================================

-- Liste TODOS os usuários cadastrados
SELECT
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- ========================================
-- 2. VERIFICAR emails_autorizados
-- ========================================

SELECT
    id,
    email,
    nome,
    autorizado,
    curso_id,
    created_at
FROM emails_autorizados
ORDER BY created_at DESC;

-- ========================================
-- 3. VERIFICAR CURSOS
-- ========================================

SELECT
    id,
    titulo,
    descricao,
    carga_horaria,
    created_at
FROM cursos
ORDER BY created_at DESC;

-- ========================================
-- 4. VERIFICAR MATRÍCULAS
-- ========================================

SELECT
    id,
    aluno_id,
    aluno_email,
    curso_id,
    progresso,
    data_matricula,
    created_at
FROM matriculas
ORDER BY created_at DESC;

-- ========================================
-- 5. VERIFICAR MATERIAIS
-- ========================================

SELECT
    id,
    curso_id,
    modulo,
    titulo,
    tipo,
    arquivo_path,
    created_at
FROM materiais
ORDER BY created_at DESC;

-- ========================================
-- 6. QUERY COMPLETA - Ver tudo junto
-- ========================================

SELECT
    u.email as usuario_email,
    u.id as usuario_id,
    ea.email as email_autorizado,
    ea.autorizado,
    ea.curso_id as curso_autorizado_id,
    c1.titulo as curso_autorizado_nome,
    m.id as matricula_id,
    m.curso_id as matricula_curso_id,
    c2.titulo as curso_matriculado_nome,
    COUNT(mat.id) as total_materiais
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c1 ON c1.id = ea.curso_id
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN cursos c2 ON c2.id = m.curso_id
LEFT JOIN materiais mat ON mat.curso_id = c2.id
GROUP BY u.email, u.id, ea.email, ea.autorizado, ea.curso_id, c1.titulo, m.id, m.curso_id, c2.titulo
ORDER BY u.created_at DESC;

-- ========================================
-- 7. CONTAR TUDO
-- ========================================

SELECT
    'Total Usuários' as item,
    COUNT(*)::text as quantidade
FROM auth.users

UNION ALL

SELECT
    'Emails Autorizados',
    COUNT(*)::text
FROM emails_autorizados
WHERE autorizado = true

UNION ALL

SELECT
    'Emails com Curso Associado',
    COUNT(*)::text
FROM emails_autorizados
WHERE autorizado = true AND curso_id IS NOT NULL

UNION ALL

SELECT
    'Total Cursos',
    COUNT(*)::text
FROM cursos

UNION ALL

SELECT
    'Total Matrículas',
    COUNT(*)::text
FROM matriculas

UNION ALL

SELECT
    'Total Materiais',
    COUNT(*)::text
FROM materiais;

-- ========================================
-- 8. VERIFICAR SE HÁ PROBLEMAS DE RELACIONAMENTO
-- ========================================

-- Matrículas com curso inexistente
SELECT
    'Matrículas com curso inexistente' as problema,
    COUNT(*)::text as quantidade
FROM matriculas m
WHERE m.curso_id NOT IN (SELECT id FROM cursos)

UNION ALL

-- Matrículas com aluno inexistente
SELECT
    'Matrículas com aluno inexistente',
    COUNT(*)::text
FROM matriculas m
WHERE m.aluno_id NOT IN (SELECT id FROM auth.users)

UNION ALL

-- Materiais com curso inexistente
SELECT
    'Materiais com curso inexistente',
    COUNT(*)::text
FROM materiais mat
WHERE mat.curso_id NOT IN (SELECT id FROM cursos)

UNION ALL

-- Emails autorizados com curso inexistente
SELECT
    'Emails autorizados com curso inexistente',
    COUNT(*)::text
FROM emails_autorizados ea
WHERE ea.curso_id IS NOT NULL
AND ea.curso_id NOT IN (SELECT id FROM cursos);

-- ========================================
-- 9. SOLUÇÃO RÁPIDA - Criar matrícula para TODOS os usuários
-- ========================================

-- IMPORTANTE: Só execute se confirmar que falta matrícula

-- Primeiro, verificar quem precisa
SELECT
    u.email,
    u.id as user_id,
    ea.curso_id,
    c.titulo as curso,
    CASE
        WHEN m.id IS NULL THEN '❌ PRECISA CRIAR MATRÍCULA'
        ELSE '✅ JÁ TEM MATRÍCULA'
    END as status
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c ON c.id = ea.curso_id
LEFT JOIN matriculas m ON m.aluno_id = u.id AND m.curso_id = ea.curso_id
WHERE ea.autorizado = true;

-- Se aparecer ❌, execute:
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
AND NOT EXISTS (
    SELECT 1 FROM matriculas m
    WHERE m.aluno_id = u.id AND m.curso_id = ea.curso_id
)
RETURNING
    aluno_email,
    curso_id,
    'MATRÍCULA CRIADA ✅' as status;

-- ========================================
-- 10. SE CURSO NÃO ESTIVER ASSOCIADO
-- ========================================

-- Ver qual curso existe
SELECT id, titulo FROM cursos;

-- Associar curso a TODOS os emails autorizados sem curso
UPDATE emails_autorizados
SET curso_id = (SELECT id FROM cursos LIMIT 1)
WHERE curso_id IS NULL
AND autorizado = true
RETURNING email, curso_id, 'CURSO ASSOCIADO ✅' as status;

-- ========================================
-- 11. VERIFICAÇÃO FINAL - Simular query do frontend
-- ========================================

-- Esta é a query que o frontend faz
-- Substitua 'USER_ID_AQUI' pelo ID do usuário que está logado

DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Pegar primeiro usuário
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;

    RAISE NOTICE 'Testando com user_id: %', test_user_id;

    -- Query que o frontend executa
    PERFORM * FROM (
        SELECT
            m.*,
            row_to_json(c.*) as cursos
        FROM matriculas m
        LEFT JOIN cursos c ON c.id = m.curso_id
        WHERE m.aluno_id = test_user_id
    ) AS result;
END $$;

-- Executar manualmente para ver resultado:
-- (Cole o user_id de um usuário real)
SELECT
    m.id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    m.progresso,
    jsonb_build_object(
        'id', c.id,
        'titulo', c.titulo,
        'carga_horaria', c.carga_horaria,
        'descricao', c.descricao
    ) as cursos
FROM matriculas m
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE m.aluno_id = 'COLE_USER_ID_AQUI';
-- ^ Substitua pelo ID real do auth.users

-- ========================================
-- RESULTADO ESPERADO
-- ========================================

/*
Após executar as queries acima, você deve ter:

1. ✅ Pelo menos 1 usuário em auth.users
2. ✅ Email do usuário em emails_autorizados com autorizado=true
3. ✅ Pelo menos 1 curso em cursos
4. ✅ emails_autorizados.curso_id apontando para curso existente
5. ✅ Matrícula em matriculas com aluno_id + curso_id
6. ✅ Materiais em materiais com curso_id correto

Se algum desses estiver faltando, use as queries de correção acima.
*/
