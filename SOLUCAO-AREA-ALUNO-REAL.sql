-- ========================================
-- SOLUÇÃO COMPLETA - Área do Aluno com Dados Reais
-- ========================================

-- PROBLEMA IDENTIFICADO:
-- Sistema usa 2 mecanismos de autorização:
-- 1. emails_autorizados (com campo curso_id)
-- 2. codigos_acesso (com campo curso_id)
-- Matrícula é criada no cadastro, mas queries podem estar incorretas

-- ========================================
-- 1. VERIFICAR E CORRIGIR ESTRUTURA
-- ========================================

-- Garantir que emails_autorizados tem curso_id
ALTER TABLE emails_autorizados
ADD COLUMN IF NOT EXISTS curso_id UUID REFERENCES cursos(id);

-- Garantir que matriculas tem aluno_email
ALTER TABLE matriculas
ADD COLUMN IF NOT EXISTS aluno_email TEXT;

-- Adicionar data_matricula se não existir
ALTER TABLE matriculas
ADD COLUMN IF NOT EXISTS data_matricula TIMESTAMP DEFAULT NOW();

-- ========================================
-- 2. CRIAR ÍNDICES PARA PERFORMANCE
-- ========================================

CREATE INDEX IF NOT EXISTS idx_matriculas_aluno_id ON matriculas(aluno_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_curso_id ON matriculas(curso_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_aluno_email ON matriculas(aluno_email);
CREATE INDEX IF NOT EXISTS idx_emails_autorizados_email ON emails_autorizados(email);
CREATE INDEX IF NOT EXISTS idx_emails_autorizados_curso_id ON emails_autorizados(curso_id);

-- ========================================
-- 3. PREENCHER aluno_email EM MATRICULAS EXISTENTES
-- ========================================

-- Atualizar matrículas com email do usuário
UPDATE matriculas m
SET aluno_email = u.email
FROM auth.users u
WHERE m.aluno_id = u.id
AND m.aluno_email IS NULL;

-- ========================================
-- 4. QUERY DE TESTE: Dados do Dashboard do Aluno
-- ========================================

-- Substituir 'USER_ID_AQUI' pelo ID do usuário logado
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Pegar primeiro usuário para teste
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;

    RAISE NOTICE 'Testando com usuário: %', test_user_id;

    -- Buscar matrículas com JOIN de cursos
    RAISE NOTICE 'Matrículas do usuário:';
    PERFORM * FROM (
        SELECT
            m.id,
            m.aluno_id,
            m.curso_id,
            m.progresso,
            c.titulo as curso,
            c.carga_horaria
        FROM matriculas m
        LEFT JOIN cursos c ON c.id = m.curso_id
        WHERE m.aluno_id = test_user_id
    ) AS result;
END $$;

-- ========================================
-- 5. QUERY PARA DASHBOARD ADMIN
-- ========================================

-- Estatísticas corretas
SELECT
    (SELECT COUNT(*) FROM emails_autorizados WHERE autorizado = true) as total_alunos_autorizados,
    (SELECT COUNT(DISTINCT aluno_id) FROM matriculas) as total_alunos_matriculados,
    (SELECT COUNT(*) FROM cursos) as total_cursos,
    (SELECT COUNT(*) FROM materiais) as total_materiais,
    (SELECT COUNT(*) FROM matriculas) as total_matriculas;

-- ========================================
-- 6. POPULAR DADOS DE TESTE (OPCIONAL)
-- ========================================

-- Comentar se já existirem dados reais

-- Criar curso de exemplo
INSERT INTO cursos (id, titulo, descricao, carga_horaria)
VALUES (
    gen_random_uuid(),
    'Curso de Inspeção Veicular',
    'Curso completo sobre inspeção veicular',
    40
)
ON CONFLICT DO NOTHING;

-- Autorizar email de teste
INSERT INTO emails_autorizados (email, autorizado, curso_id, nome)
SELECT
    'teste@exemplo.com',
    true,
    c.id,
    'Aluno Teste'
FROM cursos c
WHERE c.titulo = 'Curso de Inspeção Veicular'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Criar código de acesso de teste
INSERT INTO codigos_acesso (codigo, curso_id, usado)
SELECT
    'TESTE123',
    c.id,
    false
FROM cursos c
WHERE c.titulo = 'Curso de Inspeção Veicular'
LIMIT 1
ON CONFLICT DO NOTHING;

-- ========================================
-- 7. VERIFICAÇÃO FINAL
-- ========================================

-- Listar todos os alunos com suas matrículas
SELECT
    u.email as aluno_email,
    ea.autorizado,
    c.titulo as curso,
    m.progresso,
    m.data_matricula
FROM auth.users u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN cursos c ON c.id = m.curso_id
ORDER BY u.email;

-- Verificar se há alunos autorizados sem matrícula
SELECT
    ea.email,
    ea.nome,
    ea.curso_id,
    c.titulo as curso_autorizado
FROM emails_autorizados ea
LEFT JOIN cursos c ON c.id = ea.curso_id
WHERE ea.autorizado = true
AND ea.email NOT IN (
    SELECT DISTINCT aluno_email
    FROM matriculas
    WHERE aluno_email IS NOT NULL
);
