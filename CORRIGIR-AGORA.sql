-- ========================================
-- CORREÇÃO URGENTE - Descobrir estrutura real e corrigir
-- ========================================

-- ========================================
-- PASSO 1: DESCOBRIR ESTRUTURA REAL DAS TABELAS
-- ========================================

-- Ver colunas de emails_autorizados
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'emails_autorizados'
ORDER BY ordinal_position;

-- Ver colunas de matriculas
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'matriculas'
ORDER BY ordinal_position;

-- Ver colunas de cursos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'cursos'
ORDER BY ordinal_position;

-- Ver colunas de materiais
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'materiais'
ORDER BY ordinal_position;

-- ========================================
-- PASSO 2: VER DADOS EXISTENTES
-- ========================================

-- Ver TODOS os dados de cada tabela
SELECT 'auth.users' as tabela, COUNT(*) as total FROM auth.users
UNION ALL
SELECT 'emails_autorizados', COUNT(*) FROM emails_autorizados
UNION ALL
SELECT 'cursos', COUNT(*) FROM cursos
UNION ALL
SELECT 'matriculas', COUNT(*) FROM matriculas
UNION ALL
SELECT 'materiais', COUNT(*) FROM materiais;

-- Ver conteúdo de emails_autorizados
SELECT * FROM emails_autorizados LIMIT 10;

-- Ver conteúdo de matriculas
SELECT * FROM matriculas LIMIT 10;

-- Ver conteúdo de cursos
SELECT * FROM cursos LIMIT 10;

-- Ver conteúdo de materiais
SELECT * FROM materiais LIMIT 10;

-- ========================================
-- PASSO 3: VER USUÁRIOS
-- ========================================

SELECT
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- PASSO 4: ADICIONAR COLUNAS NECESSÁRIAS (se não existirem)
-- ========================================

-- Adicionar coluna aluno_id em matriculas (se não existir)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'matriculas' AND column_name = 'aluno_id'
    ) THEN
        ALTER TABLE matriculas ADD COLUMN aluno_id UUID REFERENCES auth.users(id);
        RAISE NOTICE 'Coluna aluno_id adicionada à tabela matriculas';
    ELSE
        RAISE NOTICE 'Coluna aluno_id já existe em matriculas';
    END IF;
END $$;

-- Adicionar coluna aluno_email em matriculas (se não existir)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'matriculas' AND column_name = 'aluno_email'
    ) THEN
        ALTER TABLE matriculas ADD COLUMN aluno_email TEXT;
        RAISE NOTICE 'Coluna aluno_email adicionada à tabela matriculas';
    ELSE
        RAISE NOTICE 'Coluna aluno_email já existe em matriculas';
    END IF;
END $$;

-- Adicionar coluna curso_id em emails_autorizados (se não existir)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'emails_autorizados' AND column_name = 'curso_id'
    ) THEN
        ALTER TABLE emails_autorizados ADD COLUMN curso_id UUID REFERENCES cursos(id);
        RAISE NOTICE 'Coluna curso_id adicionada à tabela emails_autorizados';
    ELSE
        RAISE NOTICE 'Coluna curso_id já existe em emails_autorizados';
    END IF;
END $$;

-- ========================================
-- PASSO 5: VERIFICAR ESTRUTURA APÓS CORREÇÃO
-- ========================================

-- Ver colunas atualizadas de matriculas
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'matriculas'
ORDER BY ordinal_position;

-- Ver colunas atualizadas de emails_autorizados
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'emails_autorizados'
ORDER BY ordinal_position;

-- ========================================
-- PASSO 6: CORREÇÃO SIMPLES - Usar apenas o que existe
-- ========================================

-- Ver se vmanara@gmail.com existe e onde está
SELECT
    'auth.users' as origem,
    id::text,
    email,
    created_at::text
FROM auth.users
WHERE email = 'vmanara@gmail.com'

UNION ALL

SELECT
    'emails_autorizados' as origem,
    id::text,
    email,
    created_at::text
FROM emails_autorizados
WHERE email = 'vmanara@gmail.com';

-- ========================================
-- PASSO 7: CRIAR DADOS MÍNIMOS PARA FUNCIONAR
-- ========================================

-- 1. Criar curso se não existir
INSERT INTO cursos (titulo, descricao, carga_horaria)
SELECT 'Curso de Piloto', 'Curso completo de pilotagem de aeronaves', 40
WHERE NOT EXISTS (SELECT 1 FROM cursos WHERE titulo ILIKE '%piloto%')
RETURNING id, titulo;

-- 2. Autorizar email (sem coluna nome se não existir)
DO $$
DECLARE
    v_curso_id UUID;
    v_tem_nome BOOLEAN;
BEGIN
    -- Pegar ID do curso
    SELECT id INTO v_curso_id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1;

    -- Verificar se coluna nome existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'emails_autorizados' AND column_name = 'nome'
    ) INTO v_tem_nome;

    -- Inserir com ou sem nome
    IF v_tem_nome THEN
        INSERT INTO emails_autorizados (email, autorizado, curso_id, nome)
        VALUES ('vmanara@gmail.com', true, v_curso_id, 'Vinicius Manara')
        ON CONFLICT (email) DO UPDATE
        SET autorizado = true, curso_id = v_curso_id;
    ELSE
        -- Assumir que tem apenas email e autorizado
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'emails_autorizados' AND column_name = 'curso_id'
        ) THEN
            INSERT INTO emails_autorizados (email, autorizado, curso_id)
            VALUES ('vmanara@gmail.com', true, v_curso_id)
            ON CONFLICT (email) DO UPDATE
            SET autorizado = true, curso_id = v_curso_id;
        ELSE
            INSERT INTO emails_autorizados (email, autorizado)
            VALUES ('vmanara@gmail.com', true)
            ON CONFLICT (email) DO UPDATE
            SET autorizado = true;
        END IF;
    END IF;

    RAISE NOTICE 'Email autorizado: vmanara@gmail.com';
END $$;

-- 3. Criar matrícula (adaptável)
DO $$
DECLARE
    v_user_id UUID;
    v_curso_id UUID;
    v_tem_aluno_id BOOLEAN;
    v_tem_aluno_email BOOLEAN;
BEGIN
    -- Pegar user_id
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'vmanara@gmail.com';

    -- Pegar curso_id
    SELECT curso_id INTO v_curso_id FROM emails_autorizados WHERE email = 'vmanara@gmail.com';

    IF v_user_id IS NULL THEN
        RAISE NOTICE 'Usuário vmanara@gmail.com não existe em auth.users';
        RETURN;
    END IF;

    IF v_curso_id IS NULL THEN
        RAISE NOTICE 'Curso não associado ao email vmanara@gmail.com';
        RETURN;
    END IF;

    -- Verificar quais colunas existem
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'matriculas' AND column_name = 'aluno_id'
    ) INTO v_tem_aluno_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'matriculas' AND column_name = 'aluno_email'
    ) INTO v_tem_aluno_email;

    -- Inserir conforme colunas disponíveis
    IF v_tem_aluno_id AND v_tem_aluno_email THEN
        INSERT INTO matriculas (aluno_id, aluno_email, curso_id, progresso)
        VALUES (v_user_id, 'vmanara@gmail.com', v_curso_id, 0)
        ON CONFLICT DO NOTHING;
        RAISE NOTICE 'Matrícula criada com aluno_id e aluno_email';
    ELSIF v_tem_aluno_id THEN
        INSERT INTO matriculas (aluno_id, curso_id, progresso)
        VALUES (v_user_id, v_curso_id, 0)
        ON CONFLICT DO NOTHING;
        RAISE NOTICE 'Matrícula criada com aluno_id';
    ELSE
        RAISE NOTICE 'Estrutura de matriculas incompatível - verificar colunas';
    END IF;
END $$;

-- ========================================
-- PASSO 8: VERIFICAÇÃO FINAL
-- ========================================

-- Mostrar tudo sobre vmanara@gmail.com
SELECT
    'Usuário' as tipo,
    email,
    id::text,
    created_at::text as data
FROM auth.users
WHERE email = 'vmanara@gmail.com'

UNION ALL

SELECT
    'Email Autorizado',
    email,
    id::text,
    CASE WHEN autorizado THEN 'AUTORIZADO ✅' ELSE 'NÃO AUTORIZADO ❌' END
FROM emails_autorizados
WHERE email = 'vmanara@gmail.com';

-- ========================================
-- PASSO 9: QUERY FINAL ADAPTÁVEL
-- ========================================

-- Esta query funciona independente da estrutura
DO $$
DECLARE
    v_user_id UUID;
    v_user_email TEXT;
BEGIN
    -- Pegar dados do usuário
    SELECT id, email INTO v_user_id, v_user_email
    FROM auth.users
    WHERE email = 'vmanara@gmail.com';

    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Usuário não existe em auth.users';
        RETURN;
    END IF;

    RAISE NOTICE '✅ Usuário existe: % (id: %)', v_user_email, v_user_id;

    -- Verificar emails_autorizados
    IF EXISTS (SELECT 1 FROM emails_autorizados WHERE email = v_user_email AND autorizado = true) THEN
        RAISE NOTICE '✅ Email está autorizado';
    ELSE
        RAISE NOTICE '❌ Email NÃO está autorizado';
    END IF;

    -- Verificar matrícula (adaptável)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'matriculas' AND column_name = 'aluno_id'
    ) THEN
        IF EXISTS (SELECT 1 FROM matriculas WHERE aluno_id = v_user_id) THEN
            RAISE NOTICE '✅ Tem matrícula (via aluno_id)';
        ELSE
            RAISE NOTICE '❌ NÃO tem matrícula';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela matriculas não tem coluna aluno_id';
    END IF;
END $$;
