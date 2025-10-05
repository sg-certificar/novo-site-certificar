# 🔐 Sistema Admin - CertificarCursos

Sistema administrativo completo para gerenciamento de alunos e materiais.

## 📁 Estrutura de Arquivos

```
admin/
├── index.html      # Dashboard principal
├── login.html      # Tela de login
├── style.css       # Estilos do admin
├── script.js       # Funcionalidades JS
└── README.md       # Este arquivo
```

## 🔑 Credenciais de Acesso

**Email:** `admin@certificar.app.br`
**Senha:** `EscolaAdmin2024!`

## 🌐 URLs de Acesso

- **Login:** `https://admin.certificar.app.br/login.html` ou `/admin/login.html`
- **Dashboard:** `https://admin.certificar.app.br/` ou `/admin/index.html`

## 🎯 Funcionalidades

### 1. 📊 Dashboard
- Estatísticas em tempo real
- Total de alunos autorizados
- Total de materiais cadastrados
- Total de cursos disponíveis

### 2. 👥 Gestão de Alunos
- **Autorizar novos alunos:**
  - Inserir email do aluno
  - Selecionar curso
  - Aluno recebe autorização automática

- **Listar alunos autorizados:**
  - Ver todos os emails autorizados
  - Status (Autorizado/Cadastrado)
  - Busca por email ou nome
  - Remover autorização

### 3. 📚 Gestão de Materiais
- **Upload de materiais:**
  - Drag & drop ou seleção manual
  - Organização por curso e módulo
  - Tipos: PDF, Vídeo, Documentos
  - Upload para Supabase Storage

- **Listar materiais:**
  - Ver todos os materiais cadastrados
  - Filtros por curso/módulo
  - Deletar materiais (remove do Storage e banco)

## 🔒 Segurança

- **Session Management:** 30 minutos de timeout
- **Auto-reset:** Timer resetado em atividade do usuário
- **Logout automático:** Por inatividade
- **Logs de acesso:** Registrados na tabela `admin_logs`
- **Proteção:** Redirecionamento se não autenticado

## 🗄️ Tabelas do Banco de Dados

### admin_logs
```sql
CREATE TABLE admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL,
  action TEXT NOT NULL,
  user_agent TEXT,
  timestamp TIMESTAMP DEFAULT NOW()
);
```

### emails_autorizados
```sql
CREATE TABLE emails_autorizados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  curso_id UUID REFERENCES cursos(id),
  nome_completo TEXT,
  autorizado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### materiais
```sql
CREATE TABLE materiais (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  curso_id UUID REFERENCES cursos(id),
  titulo TEXT NOT NULL,
  tipo TEXT,
  modulo TEXT,
  ordem INTEGER DEFAULT 0,
  storage_path TEXT,
  tamanho TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### cursos
```sql
CREATE TABLE cursos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo TEXT NOT NULL,
  descricao TEXT,
  carga_horaria INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 📦 Supabase Storage

### Bucket: `course-materials`

- **Configuração:**
  - Public: `false` (privado)
  - Tamanho máximo: 100MB por arquivo
  - Tipos permitidos: Todos

- **Estrutura de pastas:**
```
course-materials/
└── {curso_id}/
    └── {modulo}/
        └── {timestamp}_{arquivo}
```

### Políticas RLS (Row Level Security)

```sql
-- Permitir admins fazerem upload
CREATE POLICY "Admins podem fazer upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'course-materials');

-- Permitir admins deletarem
CREATE POLICY "Admins podem deletar"
ON storage.objects FOR DELETE
USING (bucket_id = 'course-materials');
```

## 🎨 Design System

### Cores
- **Azul primário:** `#3B82F6` - Botões principais, links
- **Verde sucesso:** `#10B981` - Alertas de sucesso, status
- **Laranja accent:** `#F59E0B` - Badges, destaques
- **Cinza dark:** `#1E293B` - Textos, sidebar
- **Branco:** `#FFFFFF` - Backgrounds
- **Cinza claro:** `#F8F9FA` - Backgrounds secundários

### Layout
- **Sidebar:** 260px fixa à esquerda
- **Content:** Responsivo com max-width
- **Cards:** Border-radius 12px, shadow suave
- **Transições:** 0.3s ease

## 📱 Responsividade

- **Desktop:** Sidebar fixa, layout completo
- **Tablet:** Sidebar colapsável, ajustes nos grids
- **Mobile:** Menu hamburger, sidebar overlay

## 🔧 Configuração Inicial

### 1. Criar Bucket no Supabase

1. Acesse o painel do Supabase
2. Vá em **Storage** → **New Bucket**
3. Nome: `course-materials`
4. Public: **false**
5. Salvar

### 2. Inserir Cursos de Exemplo

```sql
INSERT INTO cursos (titulo, descricao, carga_horaria)
VALUES
  ('Inspeção Veicular Básica', 'Curso introdutório de vistoria', 40),
  ('Inspeção Veicular Avançada', 'Curso avançado de vistoria', 60),
  ('Legislação de Trânsito', 'Legislação aplicada', 20);
```

### 3. Configurar Redirect URLs

No painel do Supabase, em **Authentication** → **URL Configuration**:

- **Site URL:** `https://certificar.app.br`
- **Redirect URLs:**
  - `https://admin.certificar.app.br/*`
  - `https://certificar.app.br/*`

## 🚀 Como Usar

### Login
1. Acesse `/admin/login.html`
2. Insira as credenciais
3. Clique em "Entrar no Painel"
4. Será redirecionado para o dashboard

### Autorizar Aluno
1. Vá em "Gestão de Alunos"
2. Preencha email do aluno
3. Selecione o curso
4. Clique em "Autorizar Aluno"
5. Aluno aparecerá na lista

### Upload de Material
1. Vá em "Gestão de Materiais"
2. Arraste arquivo ou clique para selecionar
3. Selecione curso e módulo
4. Digite título do material
5. Clique em "Enviar Material"
6. Material será enviado ao Storage e registrado no banco

## 📝 Logs e Monitoramento

Todos os acessos ao admin são registrados em `admin_logs`:

- Login bem-sucedido
- Tentativas de login falhadas
- Timestamp e user agent

## ⚡ Performance

- **Lazy loading:** Dados carregados sob demanda
- **Caching:** Session localStorage
- **Otimização:** Queries eficientes com Supabase

## 🛡️ Segurança Implementada

✅ Session timeout (30 min)
✅ HTTPS obrigatório
✅ Logs de acesso
✅ Proteção contra timing attacks
✅ Validação de uploads
✅ Storage privado
✅ RLS habilitado

## 🔮 Próximas Funcionalidades

- [ ] Dark mode
- [ ] Relatórios e gráficos
- [ ] Export de dados (CSV)
- [ ] Gestão de múltiplos admins
- [ ] Notificações em tempo real
- [ ] Backup automático
- [ ] Auditoria completa

## 📞 Suporte

Para dúvidas ou problemas, entre em contato com o desenvolvedor.

---

**Desenvolvido para CertificarCursos**
Versão 1.0 - 2025
