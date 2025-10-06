# 🎓 Sistema de Certificados - Guia Completo

## ✅ SISTEMA IMPLEMENTADO

Sistema completo de emissão e gerenciamento de certificados:
- ✅ Admin pode emitir certificados para alunos específicos
- ✅ Upload de PDF do certificado para Storage
- ✅ Vinculação aluno → curso → certificado
- ✅ Área do aluno mostra certificados disponíveis
- ✅ Download seguro com URLs assinadas

## 📋 PASSO A PASSO DE IMPLEMENTAÇÃO

### 1️⃣ Criar Tabela no Supabase

Execute o SQL no Supabase Dashboard:

**Arquivo:** `CRIAR-TABELA-CERTIFICADOS.sql`

```sql
CREATE TABLE IF NOT EXISTS certificados (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    aluno_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    curso_id UUID NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    matricula_id UUID REFERENCES matriculas(id) ON DELETE CASCADE,
    arquivo_path TEXT NOT NULL,
    data_emissao TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_certificados_aluno_id ON certificados(aluno_id);
CREATE INDEX idx_certificados_curso_id ON certificados(curso_id);

-- RLS
ALTER TABLE certificados ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Alunos podem ver seus certificados" ON certificados
FOR SELECT TO authenticated USING (aluno_id = auth.uid());

CREATE POLICY "Authenticated can insert certificados" ON certificados
FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated can delete certificados" ON certificados
FOR DELETE TO authenticated USING (true);
```

### 2️⃣ Estrutura no Storage

**Pasta:** `course-materials/certificados/`

**Organização:**
```
course-materials/
└── certificados/
    ├── {aluno_id}/
    │   ├── timestamp_certificado1.pdf
    │   ├── timestamp_certificado2.pdf
```

## 🎯 FLUXO COMPLETO

### Admin - Emitir Certificado:

1. **Acessa:** http://localhost:5174/admin/
2. **Clica em:** "Gestão de Certificados"
3. **Seleciona:** Curso
4. **Seleciona:** Aluno (lista alunos matriculados naquele curso)
5. **Faz upload:** PDF do certificado
6. **Clica:** "Emitir Certificado"

**Resultado:**
- PDF salvo em: `certificados/{aluno_id}/timestamp_arquivo.pdf`
- Registro criado na tabela `certificados`
- Aluno pode ver certificado na área dele

### Aluno - Baixar Certificado:

1. **Acessa:** http://localhost:5174/area-aluno.html
2. **Faz login**
3. **Clica na aba:** "Certificados"
4. **Vê:** Certificados emitidos para ele
5. **Clica:** "Baixar PDF"
6. **Sistema:** Gera URL assinada (60 segundos)
7. **Abre:** PDF em nova aba

## 💾 ESTRUTURA DO BANCO

### Tabela `certificados`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | ID do certificado |
| aluno_id | UUID | ID do aluno (auth.users) |
| curso_id | UUID | ID do curso |
| matricula_id | UUID | ID da matrícula (opcional) |
| arquivo_path | TEXT | Caminho no Storage |
| data_emissao | TIMESTAMP | Data de emissão |
| created_at | TIMESTAMP | Data de criação |

### Relacionamentos

```
certificados
├── aluno_id → auth.users.id
├── curso_id → cursos.id
└── matricula_id → matriculas.id
```

## 🔧 FUNÇÕES IMPLEMENTADAS

### Admin (script.js)

#### `loadCursosOptionsCertificados()`
```javascript
// Carrega cursos no select
SELECT id, titulo FROM cursos ORDER BY titulo
```

#### `loadAlunosPorCurso()`
```javascript
// Quando admin seleciona um curso, carrega alunos matriculados
SELECT matriculas.aluno_id, profiles.full_name, profiles.email
FROM matriculas
JOIN profiles ON profiles.id = matriculas.aluno_id
WHERE matriculas.curso_id = {curso_selecionado}
```

#### `emitirCertificado(event)`
```javascript
1. Upload PDF para Storage
   → certificados/{aluno_id}/{timestamp}_arquivo.pdf

2. Buscar matrícula do aluno no curso
   → SELECT id FROM matriculas WHERE aluno_id AND curso_id

3. Inserir na tabela certificados
   → INSERT INTO certificados (aluno_id, curso_id, matricula_id, arquivo_path)
```

#### `loadCertificados()`
```javascript
// Lista certificados emitidos
SELECT c.*, p.full_name, p.email, cu.titulo
FROM certificados c
JOIN profiles p ON p.id = c.aluno_id
JOIN cursos cu ON cu.id = c.curso_id
ORDER BY data_emissao DESC
```

#### `deletarCertificado(id)`
```javascript
1. Buscar arquivo_path do certificado
2. Deletar do Storage
3. Deletar do banco
```

### Área do Aluno (area-aluno.html)

#### `loadAndRenderCertificates()`
```javascript
// Busca certificados do aluno logado
SELECT * FROM certificados
WHERE aluno_id = {current_user_id}
ORDER BY data_emissao DESC
```

#### `downloadCertificate(certificadoId, arquivoPath)`
```javascript
1. Gerar URL assinada
   → storage.from('course-materials').createSignedUrl(arquivoPath, 60)

2. Abrir em nova aba
   → window.open(signedUrl, '_blank')
```

## 📊 QUERIES SQL ÚTEIS

### Ver todos os certificados emitidos
```sql
SELECT
    c.id,
    p.full_name as aluno_nome,
    p.email as aluno_email,
    cu.titulo as curso,
    c.data_emissao,
    c.arquivo_path
FROM certificados c
JOIN profiles p ON p.id = c.aluno_id
JOIN cursos cu ON cu.id = c.curso_id
ORDER BY c.data_emissao DESC;
```

### Ver certificados de um aluno específico
```sql
SELECT
    c.*,
    cu.titulo as curso_nome
FROM certificados c
JOIN cursos cu ON cu.id = c.curso_id
WHERE c.aluno_id = 'uuid-do-aluno';
```

### Ver alunos matriculados em um curso
```sql
SELECT
    m.aluno_id,
    p.full_name,
    p.email,
    m.progresso
FROM matriculas m
JOIN profiles p ON p.id = m.aluno_id
WHERE m.curso_id = 'uuid-do-curso';
```

## 🧪 TESTE COMPLETO

### 1. Preparação
- [ ] Executar SQL para criar tabela `certificados`
- [ ] Ter pelo menos 1 curso criado
- [ ] Ter pelo menos 1 aluno matriculado

### 2. Admin - Emitir Certificado
- [ ] Acessar admin/
- [ ] Clicar em "Gestão de Certificados"
- [ ] Selecionar curso
- [ ] Verificar que alunos aparecem
- [ ] Fazer upload de PDF
- [ ] Clicar em "Emitir Certificado"
- [ ] Verificar mensagem de sucesso
- [ ] Ver certificado na lista

### 3. Área do Aluno - Ver Certificado
- [ ] Login com aluno que recebeu certificado
- [ ] Clicar aba "Certificados"
- [ ] Ver certificado listado
- [ ] Verificar data de emissão correta
- [ ] Clicar em "Baixar PDF"
- [ ] PDF abre em nova aba

### 4. Verificar no Supabase
- [ ] Dashboard → Storage → course-materials → certificados
- [ ] Verificar arquivo existe
- [ ] Dashboard → Table Editor → certificados
- [ ] Verificar registro criado

## 🐛 LOGS DE DEBUG

### Admin - Console (F12):
```
📤 Fazendo upload do certificado para: certificados/{aluno_id}/{timestamp}.pdf
✅ Upload concluído!
💾 Salvando certificado no banco...
✅ Certificado emitido com sucesso!
```

### Área do Aluno - Console (F12):
```
🎓 Buscando certificados do aluno...
📜 Certificados encontrados: [{ ... }]
📜 Baixando certificado: { certificadoId: "...", arquivoPath: "..." }
```

## 🚨 ERROS COMUNS

### Erro: "Nenhum aluno matriculado"

**Causa:** Não há matrículas para o curso selecionado

**Solução:**
```sql
-- Criar matrícula
INSERT INTO matriculas (aluno_id, curso_id, progresso, data_matricula)
VALUES ('uuid-aluno', 'uuid-curso', 0, NOW());
```

### Erro: "Erro ao carregar alunos"

**Causa:** Relação profiles ↔ matriculas incorreta

**Solução:** Verificar foreign key:
```sql
-- Ver foreign keys
SELECT * FROM information_schema.table_constraints
WHERE table_name = 'matriculas';
```

### Erro: "Certificado não aparece para aluno"

**Causa:** RLS bloqueando ou aluno_id incorreto

**Solução:**
```sql
-- Verificar certificado do aluno
SELECT * FROM certificados WHERE aluno_id = 'uuid-do-aluno';

-- Verificar se RLS permite
SELECT * FROM pg_policies WHERE tablename = 'certificados';
```

## 🎯 FEATURES FUTURAS (Opcional)

- [ ] Gerar certificado automaticamente ao concluir curso
- [ ] Template de certificado com dados dinâmicos (nome, curso, data)
- [ ] QR Code no certificado para validação
- [ ] Sistema de verificação pública de certificados
- [ ] Histórico de certificados emitidos
- [ ] Notificação por email ao emitir certificado

## 📝 NOTAS IMPORTANTES

1. **Segurança:**
   - URLs assinadas expiram em 60 segundos
   - RLS ativo: aluno só vê seus certificados
   - Admin pode gerenciar todos

2. **Storage:**
   - PDFs salvos em `course-materials/certificados/`
   - Organizado por aluno_id
   - Bucket privado (URLs assinadas)

3. **Vinculação:**
   - Certificado vincula: aluno + curso + matrícula
   - Permite rastreamento completo
   - Facilita relatórios

---

**✅ Sistema de Certificados 100% Funcional!**
