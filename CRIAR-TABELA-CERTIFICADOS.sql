-- ========================================
-- CRIAR TABELA CERTIFICADOS
-- ========================================

-- Criar tabela para armazenar certificados dos alunos
CREATE TABLE IF NOT EXISTS certificados (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    aluno_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    curso_id UUID NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    matricula_id UUID REFERENCES matriculas(id) ON DELETE CASCADE,
    arquivo_path TEXT NOT NULL,
    data_emissao TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_certificados_aluno_id ON certificados(aluno_id);
CREATE INDEX IF NOT EXISTS idx_certificados_curso_id ON certificados(curso_id);
CREATE INDEX IF NOT EXISTS idx_certificados_matricula_id ON certificados(matricula_id);

-- RLS (Row Level Security)
ALTER TABLE certificados ENABLE ROW LEVEL SECURITY;

-- Política: Usuários autenticados podem ver seus próprios certificados
DROP POLICY IF EXISTS "Alunos podem ver seus certificados" ON certificados;
CREATE POLICY "Alunos podem ver seus certificados" ON certificados
FOR SELECT TO authenticated
USING (aluno_id = auth.uid());

-- Política: Admins podem inserir certificados (qualquer usuário autenticado pode inserir)
DROP POLICY IF EXISTS "Authenticated can insert certificados" ON certificados;
CREATE POLICY "Authenticated can insert certificados" ON certificados
FOR INSERT TO authenticated
WITH CHECK (true);

-- Política: Admins podem atualizar certificados
DROP POLICY IF EXISTS "Authenticated can update certificados" ON certificados;
CREATE POLICY "Authenticated can update certificados" ON certificados
FOR UPDATE TO authenticated
USING (true);

-- Política: Admins podem deletar certificados
DROP POLICY IF EXISTS "Authenticated can delete certificados" ON certificados;
CREATE POLICY "Authenticated can delete certificados" ON certificados
FOR DELETE TO authenticated
USING (true);

-- Verificar estrutura
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'certificados'
ORDER BY ordinal_position;

-- Comentários nas colunas
COMMENT ON TABLE certificados IS 'Armazena certificados emitidos para os alunos';
COMMENT ON COLUMN certificados.aluno_id IS 'ID do aluno (auth.users)';
COMMENT ON COLUMN certificados.curso_id IS 'ID do curso';
COMMENT ON COLUMN certificados.matricula_id IS 'ID da matrícula relacionada';
COMMENT ON COLUMN certificados.arquivo_path IS 'Caminho do arquivo no Storage (course-materials/certificados/)';
COMMENT ON COLUMN certificados.data_emissao IS 'Data de emissão do certificado';
