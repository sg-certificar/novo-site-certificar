-- ========================================
-- VERIFICAR E PREPARAR DADOS - vmanara@gmail.com
-- ========================================

-- 1. VERIFICAR SE EMAIL ESTÁ AUTORIZADO
SELECT
    id,
    email,
    nome,
    autorizado,
    curso_id
FROM emails_autorizados
WHERE email = 'vmanara@gmail.com';

-- Se NÃO retornar resultado, o email não está cadastrado
-- Se curso_id for NULL, não tem curso associado

-- ========================================
-- 2. VERIFICAR SE CURSO 'Curso de Piloto' EXISTE
-- ========================================

SELECT
    id,
    titulo,
    descricao,
    carga_horaria
FROM cursos
WHERE titulo ILIKE '%piloto%';

-- ========================================
-- 3. ASSOCIAR CURSO AO EMAIL AUTORIZADO
-- ========================================

-- Atualizar emails_autorizados com o curso_id correto
UPDATE emails_autorizados
SET curso_id = (
    SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1
)
WHERE email = 'vmanara@gmail.com';

-- Confirmar atualização
SELECT
    email,
    autorizado,
    curso_id,
    c.titulo as curso_titulo
FROM emails_autorizados ea
LEFT JOIN cursos c ON c.id = ea.curso_id
WHERE email = 'vmanara@gmail.com';

-- ========================================
-- 4. VERIFICAR SE USUÁRIO EXISTE EM auth.users
-- ========================================

SELECT
    id,
    email,
    created_at
FROM auth.users
WHERE email = 'vmanara@gmail.com';

-- ========================================
-- 5. VERIFICAR MATRÍCULAS EXISTENTES
-- ========================================

SELECT
    m.id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    c.titulo as curso_titulo,
    m.progresso,
    m.data_matricula
FROM matriculas m
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE m.aluno_email = 'vmanara@gmail.com'
   OR m.aluno_id IN (SELECT id FROM auth.users WHERE email = 'vmanara@gmail.com');

-- ========================================
-- 6. CRIAR MATRÍCULA MANUALMENTE (se necessário)
-- ========================================

-- Só execute se o login automático não criar
INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso, data_matricula)
SELECT
    u.id,
    u.email,
    ea.curso_id,
    0,
    NOW()
FROM auth.users u
CROSS JOIN emails_autorizados ea
WHERE u.email = 'vmanara@gmail.com'
AND ea.email = 'vmanara@gmail.com'
AND ea.autorizado = true
AND ea.curso_id IS NOT NULL
-- Evitar duplicatas
AND NOT EXISTS (
    SELECT 1 FROM matriculas m
    WHERE m.aluno_id = u.id AND m.curso_id = ea.curso_id
);

-- ========================================
-- 7. VERIFICAÇÃO FINAL - Ver tudo junto
-- ========================================

SELECT
    'auth.users' as tabela,
    u.id as user_id,
    u.email as user_email,
    ea.autorizado,
    ea.curso_id as email_curso_id,
    c1.titulo as curso_autorizado,
    m.id as matricula_id,
    m.curso_id as matricula_curso_id,
    c2.titulo as curso_matriculado,
    m.progresso
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c1 ON c1.id = ea.curso_id
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN cursos c2 ON c2.id = m.curso_id
WHERE u.email = 'vmanara@gmail.com';

-- ========================================
-- 8. CONTAR MATERIAIS DO CURSO
-- ========================================

SELECT
    c.titulo as curso,
    COUNT(mat.id) as total_materiais,
    STRING_AGG(DISTINCT mat.modulo, ', ') as modulos
FROM cursos c
LEFT JOIN materiais mat ON mat.curso_id = c.id
WHERE c.titulo ILIKE '%piloto%'
GROUP BY c.id, c.titulo;

-- ========================================
-- 9. RESULTADO ESPERADO
-- ========================================

-- Após executar os comandos acima, você deve ter:
-- ✅ Email vmanara@gmail.com em emails_autorizados com autorizado=true
-- ✅ curso_id preenchido apontando para 'Curso de Piloto'
-- ✅ Usuário em auth.users com email vmanara@gmail.com
-- ✅ Matrícula em matriculas ligando aluno_id ao curso_id

-- Quando vmanara@gmail.com fizer login:
-- 1. Sistema busca email em emails_autorizados ✅
-- 2. Encontra curso_id do 'Curso de Piloto' ✅
-- 3. Cria matrícula automática (se não existir) ✅
-- 4. Dashboard mostra 'Curso de Piloto' com materiais ✅
