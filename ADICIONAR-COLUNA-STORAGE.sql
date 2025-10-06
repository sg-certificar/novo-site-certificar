-- ========================================
-- ADICIONAR COLUNAS FALTANTES NA TABELA materiais
-- ========================================

-- Adicionar storage_path
ALTER TABLE materiais
ADD COLUMN IF NOT EXISTS storage_path TEXT;

-- Adicionar tamanho
ALTER TABLE materiais
ADD COLUMN IF NOT EXISTS tamanho TEXT;

-- Verificar estrutura final
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'materiais'
ORDER BY ordinal_position;
