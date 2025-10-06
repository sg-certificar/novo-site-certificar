# 🚨 RESOLVER: Área do Aluno Não Carrega Cursos

## 🔍 DIAGNÓSTICO RÁPIDO

### **Passo 1: Abrir Console do Navegador**

1. Acesse: http://localhost:5174/area-aluno.html
2. Faça login
3. Pressione **F12** (abre DevTools)
4. Vá na aba **Console**
5. Procure por mensagens de erro ou warnings

**O que procurar**:
```
⚠️ Nenhuma matrícula encontrada para este usuário
❌ Erro ao carregar matrículas: ...
```

---

### **Passo 2: Ver qual usuário está logado**

No console, deve aparecer:
```javascript
👤 Carregando dados para usuário: {
  id: "abc-123-def-456",  // ← COPIE ESTE ID
  email: "vmanara@gmail.com"
}
```

**COPIE o `id` do usuário** para usar nas queries.

---

### **Passo 3: Executar Diagnóstico no Supabase**

Abra **Supabase SQL Editor** e execute:

#### **3.1 Ver se usuário existe**
```sql
SELECT id, email FROM auth.users WHERE email = 'vmanara@gmail.com';
```

**Resultado esperado**:
```
id                  | email
--------------------|------------------
abc-123-def-456     | vmanara@gmail.com
```

Se **não retornar nada**: usuário não foi criado. Crie conta novamente.

---

#### **3.2 Ver se email está autorizado**
```sql
SELECT
    email,
    autorizado,
    curso_id,
    (SELECT titulo FROM cursos WHERE id = curso_id) as curso
FROM emails_autorizados
WHERE email = 'vmanara@gmail.com';
```

**Resultado esperado**:
```
email             | autorizado | curso_id    | curso
------------------|------------|-------------|----------------
vmanara@gmail.com | true       | def-456-abc | Curso de Piloto
```

**Problemas possíveis**:

| Problema | Solução |
|----------|---------|
| Não retorna nada | Email não foi autorizado no admin |
| `autorizado = false` | Precisa ativar no admin |
| `curso_id = NULL` | Precisa associar curso (veja Passo 4) |
| `curso = NULL` | Curso não existe (veja Passo 5) |

---

#### **3.3 Ver se tem matrícula**
```sql
SELECT
    m.id,
    m.aluno_id,
    m.aluno_email,
    m.curso_id,
    c.titulo as curso
FROM matriculas m
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE m.aluno_email = 'vmanara@gmail.com'
   OR m.aluno_id = 'abc-123-def-456';  -- Use o ID copiado do Passo 2
```

**Resultado esperado**:
```
aluno_email       | curso_id | curso
------------------|----------|----------------
vmanara@gmail.com | def-456  | Curso de Piloto
```

**Se não retornar nada**: Não tem matrícula! Vá para o **Passo 6**.

---

### **Passo 4: Se curso_id está NULL**

Execute:
```sql
-- Ver quais cursos existem
SELECT id, titulo FROM cursos;

-- Associar curso ao email
UPDATE emails_autorizados
SET curso_id = (SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1)
WHERE email = 'vmanara@gmail.com';

-- Confirmar
SELECT email, curso_id FROM emails_autorizados WHERE email = 'vmanara@gmail.com';
```

---

### **Passo 5: Se não existe nenhum curso**

Execute:
```sql
-- Criar curso
INSERT INTO cursos (titulo, descricao, carga_horaria)
VALUES (
    'Curso de Piloto',
    'Curso completo de pilotagem de aeronaves',
    40
)
RETURNING id, titulo;
```

Depois execute **Passo 4** para associar.

---

### **Passo 6: Criar Matrícula Manualmente**

**IMPORTANTE**: Use o `user.id` real do Passo 2

```sql
-- Criar matrícula
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
AND ea.curso_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM matriculas m
    WHERE m.aluno_id = u.id AND m.curso_id = ea.curso_id
)
RETURNING *;
```

**Resultado esperado**:
```
✅ Matrícula criada:
aluno_id: abc-123-def-456
aluno_email: vmanara@gmail.com
curso_id: def-456-abc
```

---

### **Passo 7: Verificar Materiais**

```sql
-- Ver materiais do curso
SELECT
    m.id,
    m.curso_id,
    c.titulo as curso,
    m.modulo,
    m.titulo as material,
    m.tipo,
    m.arquivo_path
FROM materiais m
LEFT JOIN cursos c ON c.id = m.curso_id
WHERE c.titulo ILIKE '%piloto%'
ORDER BY m.modulo, m.created_at;
```

**Se não retornar nada**: Não há materiais cadastrados. Admin precisa fazer upload.

---

### **Passo 8: Testar Novamente**

1. **Volte para** http://localhost:5174/area-aluno.html
2. **Faça logout** (se estiver logado)
3. **Faça login** novamente com `vmanara@gmail.com`
4. **Veja o console** (F12):
   ```
   🔍 Verificando autorização para: vmanara@gmail.com
   ✅ Email autorizado encontrado: {...}
   ℹ️ Matrícula já existe
   ```
   OU (se criou agora):
   ```
   📝 Criando matrícula automática...
   ✅ Matrícula criada com sucesso
   ```

5. **Dashboard deve mostrar**:
   ```
   🎓 Cursos Matriculados: 1
   ✈️ Curso de Piloto
   ```

---

## 🐛 PROBLEMAS COMUNS

### **Problema 1: "Nenhuma matrícula encontrada"**

**Causa**: Falta matrícula na tabela `matriculas`

**Solução**: Execute **Passo 6**

---

### **Problema 2: Dashboard mostra curso mas não mostra materiais**

**Causa**: Não há materiais cadastrados OU curso_id dos materiais está errado

**Verificar**:
```sql
-- Ver materiais
SELECT COUNT(*), curso_id FROM materiais GROUP BY curso_id;

-- Ver IDs dos cursos
SELECT id, titulo FROM cursos;
```

**Solução**: Se `curso_id` dos materiais não corresponder ao curso da matrícula:
```sql
-- Corrigir curso_id dos materiais
UPDATE materiais
SET curso_id = (SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1)
WHERE curso_id IS NULL OR curso_id NOT IN (SELECT id FROM cursos);
```

---

### **Problema 3: "Email não encontrado em emails_autorizados"**

**Causa**: Email não foi autorizado no admin

**Solução**:
```sql
-- Criar email autorizado
INSERT INTO emails_autorizados (email, autorizado, curso_id, nome)
VALUES (
    'vmanara@gmail.com',
    true,
    (SELECT id FROM cursos WHERE titulo ILIKE '%piloto%' LIMIT 1),
    'Vinicius Manara'
)
ON CONFLICT (email) DO UPDATE
SET autorizado = true,
    curso_id = EXCLUDED.curso_id;
```

---

### **Problema 4: Erro "null value in column curso_id violates not-null constraint"**

**Causa**: Tentando criar matrícula sem curso_id

**Solução**: Execute **Passo 4** primeiro para associar curso ao email autorizado

---

### **Problema 5: Console não mostra logs**

**Causa**: JavaScript com erro ou página não carregou

**Verificar**:
1. Aba **Console** tem erros em vermelho?
2. Aba **Network** mostra requisições falhando?

**Solução**: Se tiver erro de CORS ou Supabase:
- Verifique se `SUPABASE_URL` e `SUPABASE_ANON_KEY` estão corretos em `config.js`

---

## ✅ CHECKLIST RÁPIDO

Execute na ordem:

- [ ] **1. Console mostra user.id e user.email?**
  - Se não: Problema de autenticação
  - Se sim: Copie o ID

- [ ] **2. auth.users tem o usuário?**
  ```sql
  SELECT * FROM auth.users WHERE email = 'vmanara@gmail.com';
  ```

- [ ] **3. emails_autorizados tem o email?**
  ```sql
  SELECT * FROM emails_autorizados WHERE email = 'vmanara@gmail.com';
  ```

- [ ] **4. emails_autorizados.curso_id está preenchido?**
  - Se não: Execute Passo 4

- [ ] **5. Curso existe em cursos?**
  ```sql
  SELECT * FROM cursos;
  ```
  - Se não: Execute Passo 5

- [ ] **6. matriculas tem registro do usuário?**
  ```sql
  SELECT * FROM matriculas WHERE aluno_email = 'vmanara@gmail.com';
  ```
  - Se não: Execute Passo 6

- [ ] **7. materiais existem para o curso?**
  ```sql
  SELECT * FROM materiais WHERE curso_id = (SELECT curso_id FROM emails_autorizados WHERE email = 'vmanara@gmail.com');
  ```

- [ ] **8. Logout + Login novamente**

- [ ] **9. Dashboard mostra curso?**

---

## 📊 QUERY MÁGICA - Ver Tudo de Uma Vez

Execute esta query para ver tudo sobre um usuário:

```sql
WITH user_data AS (
    SELECT id, email FROM auth.users WHERE email = 'vmanara@gmail.com'
)
SELECT
    '1. Usuário Existe' as passo,
    CASE WHEN u.id IS NOT NULL THEN '✅' ELSE '❌' END as status,
    u.email as detalhe
FROM user_data u

UNION ALL

SELECT
    '2. Email Autorizado',
    CASE WHEN ea.autorizado THEN '✅' ELSE '❌' END,
    'autorizado: ' || ea.autorizado::text
FROM user_data u
LEFT JOIN emails_autorizados ea ON ea.email = u.email

UNION ALL

SELECT
    '3. Curso Associado',
    CASE WHEN ea.curso_id IS NOT NULL THEN '✅' ELSE '❌' END,
    COALESCE(c.titulo, 'SEM CURSO')
FROM user_data u
LEFT JOIN emails_autorizados ea ON ea.email = u.email
LEFT JOIN cursos c ON c.id = ea.curso_id

UNION ALL

SELECT
    '4. Tem Matrícula',
    CASE WHEN m.id IS NOT NULL THEN '✅' ELSE '❌' END,
    'matrícula_id: ' || COALESCE(m.id::text, 'SEM MATRÍCULA')
FROM user_data u
LEFT JOIN matriculas m ON m.aluno_id = u.id

UNION ALL

SELECT
    '5. Curso Matriculado',
    CASE WHEN mc.id IS NOT NULL THEN '✅' ELSE '❌' END,
    COALESCE(mc.titulo, 'SEM CURSO NA MATRÍCULA')
FROM user_data u
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN cursos mc ON mc.id = m.curso_id

UNION ALL

SELECT
    '6. Tem Materiais',
    CASE WHEN COUNT(mat.id) > 0 THEN '✅' ELSE '❌' END,
    'total: ' || COUNT(mat.id)::text
FROM user_data u
LEFT JOIN matriculas m ON m.aluno_id = u.id
LEFT JOIN materiais mat ON mat.curso_id = m.curso_id
GROUP BY u.id;
```

**Resultado esperado** (tudo ✅):
```
passo                 | status | detalhe
----------------------|--------|---------------------------
1. Usuário Existe     | ✅     | vmanara@gmail.com
2. Email Autorizado   | ✅     | autorizado: true
3. Curso Associado    | ✅     | Curso de Piloto
4. Tem Matrícula      | ✅     | matrícula_id: abc-123
5. Curso Matriculado  | ✅     | Curso de Piloto
6. Tem Materiais      | ✅     | total: 5
```

Se algum passo estiver **❌**, use as soluções acima.

---

## 🆘 ÚLTIMO RECURSO - Recriar Tudo

Se nada funcionar, recrie o usuário do zero:

```sql
-- 1. Deletar dados antigos
DELETE FROM matriculas WHERE aluno_email = 'vmanara@gmail.com';
DELETE FROM emails_autorizados WHERE email = 'vmanara@gmail.com';
-- NÃO delete de auth.users - deixe o usuário existir

-- 2. Recriar email autorizado
INSERT INTO emails_autorizados (email, autorizado, curso_id, nome)
VALUES (
    'vmanara@gmail.com',
    true,
    (SELECT id FROM cursos LIMIT 1),
    'Vinicius Manara'
);

-- 3. Fazer login novamente na área do aluno
-- Sistema criará matrícula automaticamente
```

---

## 📞 SUPORTE

Se continuar com problema, envie:

1. **Screenshot do console** (F12)
2. **Resultado da Query Mágica** acima
3. **Resultado de**:
   ```sql
   SELECT COUNT(*) FROM auth.users;
   SELECT COUNT(*) FROM emails_autorizados;
   SELECT COUNT(*) FROM cursos;
   SELECT COUNT(*) FROM matriculas;
   SELECT COUNT(*) FROM materiais;
   ```
