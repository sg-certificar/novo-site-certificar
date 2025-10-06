-- ========================================
-- CORREÇÃO SISTEMA COMPLETO - Usar emails_autorizados
-- ========================================

-- 1. VERIFICAR TABELAS EXISTENTES
SELECT 'emails_autorizados' as tabela, COUNT(*) as registros FROM emails_autorizados
UNION ALL
SELECT 'cursos', COUNT(*) FROM cursos
UNION ALL
SELECT 'materiais', COUNT(*) FROM materiais
UNION ALL
SELECT 'matriculas', COUNT(*) FROM matriculas
UNION ALL
SELECT 'certificados', COUNT(*) FROM certificados;

-- 2. ESTRUTURA DA TABELA emails_autorizados
-- Verificar colunas disponíveis
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'emails_autorizados'
ORDER BY ordinal_position;

-- 3. ADICIONAR COLUNAS NECESSÁRIAS em emails_autorizados (se não existirem)
ALTER TABLE emails_autorizados
ADD COLUMN IF NOT EXISTS nome TEXT,
ADD COLUMN IF NOT EXISTS telefone TEXT,
ADD COLUMN IF NOT EXISTS cidade TEXT;

-- 4. VERIFICAR ESTRUTURA DE MATRICULAS
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'matriculas'
ORDER BY ordinal_position;

-- 5. GARANTIR QUE MATRICULAS TEM COLUNA aluno_email
ALTER TABLE matriculas
ADD COLUMN IF NOT EXISTS aluno_email TEXT;

-- 6. CRIAR ÍNDICE PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_matriculas_aluno_email ON matriculas(aluno_email);
CREATE INDEX IF NOT EXISTS idx_emails_autorizados_email ON emails_autorizados(email);

-- 7. QUERY DE TESTE: Listar alunos autorizados com seus cursos
SELECT
    ea.email,
    ea.nome,
    ea.autorizado,
    c.titulo as curso,
    m.progresso
FROM emails_autorizados ea
LEFT JOIN matriculas m ON m.aluno_email = ea.email
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE ea.autorizado = true
ORDER BY ea.email, c.titulo;

-- 8. QUERY DE TESTE: Estatísticas do dashboard
SELECT
    (SELECT COUNT(*) FROM emails_autorizados WHERE autorizado = true) as total_alunos,
    (SELECT COUNT(*) FROM cursos) as total_cursos,
    (SELECT COUNT(*) FROM materiais) as total_materiais,
    (SELECT COUNT(*) FROM matriculas) as total_matriculas;
