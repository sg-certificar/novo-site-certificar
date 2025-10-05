# 🔐 Auth Middleware - Guia de Uso

Middleware de autenticação compartilhado para admin e alunos.

## 📦 Instalação

### 1. Incluir scripts nas páginas

```html
<!-- Ordem importante: Supabase primeiro, depois middleware -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="/auth-middleware.js"></script>
```

### 2. Inicializar Supabase

```javascript
// No início do seu script
const SUPABASE_URL = 'https://jfgnelowaaiwuzwelbot.supabase.co';
const SUPABASE_ANON_KEY = 'sua-anon-key';

const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Inicializar middleware
AuthMiddleware.initSupabase(supabaseClient);
```

## 🎯 Funções Principais

### ✅ Verificações de Autenticação

#### `checkAdminAuth()`
Verifica se usuário é admin válido.

```javascript
const isAdmin = await AuthMiddleware.checkAdminAuth();
if (isAdmin) {
    console.log('Usuário é admin');
}
```

#### `checkStudentAuth()`
Verifica se usuário é aluno autenticado.

```javascript
const isStudent = await AuthMiddleware.checkStudentAuth();
if (isStudent) {
    console.log('Usuário é aluno');
}
```

#### `getCurrentUser()`
Obtém dados do usuário atual (admin ou aluno).

```javascript
const user = await AuthMiddleware.getCurrentUser();
if (user) {
    console.log('Tipo:', user.type); // 'admin' ou 'student'
    console.log('Dados:', user.data);
}
```

### 🔄 Redirecionamentos

#### `redirectToLogin(userType, message)`
Redireciona para login apropriado.

```javascript
// Redirecionar para login de aluno
AuthMiddleware.redirectToLogin('student', 'Sessão expirada');

// Redirecionar para login de admin
AuthMiddleware.redirectToLogin('admin', 'Acesso negado');
```

#### `redirectToDashboard(userType)`
Redireciona para dashboard apropriado.

```javascript
// Após login bem-sucedido
AuthMiddleware.redirectToDashboard('admin');
```

### 🔑 Login

#### `loginAdmin(email, password)`
Login de administrador.

```javascript
const result = await AuthMiddleware.loginAdmin(email, password);
if (result.success) {
    AuthMiddleware.redirectToDashboard('admin');
} else {
    alert(result.message);
}
```

#### `loginStudent(email, password)`
Login de aluno via Supabase Auth.

```javascript
const result = await AuthMiddleware.loginStudent(email, password);
if (result.success) {
    AuthMiddleware.redirectToDashboard('student');
} else {
    alert(result.message);
}
```

### 🚪 Logout

#### `logout(userType)`
Logout universal (auto-detecta tipo se não fornecido).

```javascript
// Auto-detecta tipo
await AuthMiddleware.logout();

// Ou especificar tipo
await AuthMiddleware.logout('admin');
```

### 🔐 Recuperação e Alteração de Senha

#### `resetPassword(email)`
Envia email de recuperação de senha.

```javascript
const result = await AuthMiddleware.resetPassword(email);
if (result.success) {
    alert(result.message);
}
```

#### `updatePassword(newPassword, currentPassword)`
Atualiza senha do usuário logado.

```javascript
const result = await AuthMiddleware.updatePassword(
    'NovaSenha123!',
    'SenhaAtual123'
);

if (result.success) {
    alert('Senha atualizada!');
}
```

#### `validatePasswordStrength(password)`
Valida força da senha.

```javascript
const validation = AuthMiddleware.validatePasswordStrength('MinhaSenh@123');

console.log(validation.isValid); // true/false
console.log(validation.message); // Mensagem de feedback
console.log(validation.strength); // 0-4 (força)
```

### 🛡️ Guards de Página

#### `requireAdmin()`
Protege página admin - redireciona se não for admin.

```javascript
// No início da página admin
document.addEventListener('DOMContentLoaded', async () => {
    await AuthMiddleware.requireAdmin();
    // Código da página continua apenas se for admin
    loadAdminData();
});
```

#### `requireStudent()`
Protege página de aluno - redireciona se não autenticado.

```javascript
// No início da área do aluno
document.addEventListener('DOMContentLoaded', async () => {
    await AuthMiddleware.requireStudent();
    // Código continua apenas se for aluno autenticado
    loadStudentData();
});
```

### ⏰ Session Management

#### `startAdminSessionTimer()`
Inicia timer de sessão para admin (auto logout 30min).

```javascript
// Após login admin bem-sucedido
AuthMiddleware.startAdminSessionTimer();
```

#### `enableAutoResetTimer()`
Ativa reset automático do timer em atividades do usuário.

```javascript
// Ativar uma vez no início
AuthMiddleware.enableAutoResetTimer();
```

#### `resetSessionTimer()`
Reset manual do timer de sessão.

```javascript
// Chamar em ações importantes
AuthMiddleware.resetSessionTimer();
```

### 🔧 Utilitários

#### `getLoginMessage()`
Obtém mensagem de login (se houver).

```javascript
const message = AuthMiddleware.getLoginMessage();
if (message) {
    showAlert(message);
}
```

#### `logAccess(email, action)`
Registra log de acesso/ação.

```javascript
await AuthMiddleware.logAccess('user@email.com', 'login_success');
```

## 📝 Exemplos Completos

### Exemplo 1: Página Admin Protegida

```html
<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
</head>
<body>
    <h1>Dashboard Admin</h1>
    <button onclick="handleLogout()">Sair</button>

    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
    <script src="/auth-middleware.js"></script>
    <script>
        // Inicializar
        const { createClient } = supabase;
        const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        AuthMiddleware.initSupabase(supabaseClient);

        // Proteger página
        document.addEventListener('DOMContentLoaded', async () => {
            // Guard automático
            await AuthMiddleware.requireAdmin();

            // Ativar auto-reset de sessão
            AuthMiddleware.enableAutoResetTimer();

            // Carregar dados admin
            loadAdminData();
        });

        async function handleLogout() {
            await AuthMiddleware.logout('admin');
        }

        function loadAdminData() {
            console.log('Carregando dados do admin...');
        }
    </script>
</body>
</html>
```

### Exemplo 2: Login de Aluno

```html
<!DOCTYPE html>
<html>
<head>
    <title>Login Aluno</title>
</head>
<body>
    <form id="loginForm">
        <input type="email" id="email" required>
        <input type="password" id="password" required>
        <button type="submit">Entrar</button>
    </form>

    <a href="#" onclick="showResetPassword()">Esqueci minha senha</a>

    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
    <script src="/auth-middleware.js"></script>
    <script>
        // Inicializar
        const { createClient } = supabase;
        const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        AuthMiddleware.initSupabase(supabaseClient);

        // Verificar mensagem de login
        document.addEventListener('DOMContentLoaded', () => {
            const message = AuthMiddleware.getLoginMessage();
            if (message) {
                alert(message);
            }
        });

        // Login
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();

            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;

            const result = await AuthMiddleware.loginStudent(email, password);

            if (result.success) {
                AuthMiddleware.redirectToDashboard('student');
            } else {
                alert(result.message);
            }
        });

        // Recuperação de senha
        async function showResetPassword() {
            const email = prompt('Digite seu email:');
            if (email) {
                const result = await AuthMiddleware.resetPassword(email);
                alert(result.message);
            }
        }
    </script>
</body>
</html>
```

### Exemplo 3: Alteração de Senha

```html
<form id="changePasswordForm">
    <input type="password" id="currentPassword" placeholder="Senha atual" required>
    <input type="password" id="newPassword" placeholder="Nova senha" required>
    <input type="password" id="confirmPassword" placeholder="Confirmar senha" required>
    <button type="submit">Alterar Senha</button>
</form>

<script>
    document.getElementById('changePasswordForm').addEventListener('submit', async (e) => {
        e.preventDefault();

        const currentPassword = document.getElementById('currentPassword').value;
        const newPassword = document.getElementById('newPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;

        // Validar senhas iguais
        if (newPassword !== confirmPassword) {
            alert('As senhas não conferem!');
            return;
        }

        // Validar força da senha
        const validation = AuthMiddleware.validatePasswordStrength(newPassword);
        if (!validation.isValid) {
            alert(validation.message);
            return;
        }

        // Atualizar senha
        const result = await AuthMiddleware.updatePassword(newPassword, currentPassword);

        if (result.success) {
            alert('Senha alterada com sucesso!');
            e.target.reset();
        } else {
            alert(result.message);
        }
    });
</script>
```

## 🔒 Segurança

### Configurações de Sessão

- **Timeout:** 30 minutos de inatividade
- **Auto-reset:** Timer resetado em atividades do usuário
- **Logs:** Todas as ações são registradas

### Credenciais Admin

Definidas em `auth-middleware.js`:
```javascript
const ADMIN_EMAIL = 'admin@certificar.app.br';
const ADMIN_PASSWORD = 'EscolaAdmin2024!';
```

### Validação de Senha

Requisitos mínimos:
- Mínimo 6 caracteres
- Recomendado: maiúsculas, minúsculas, números e caracteres especiais

## 📊 Estrutura de Logs

Tabela `admin_logs` no Supabase:

```sql
CREATE TABLE admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL,
  action TEXT NOT NULL,
  user_agent TEXT,
  timestamp TIMESTAMP DEFAULT NOW()
);
```

Ações registradas:
- `admin_login_success`
- `admin_login_failed`
- `student_login_success`
- `student_login_failed`
- `password_reset_requested`
- `password_updated`

## 🚀 Boas Práticas

1. **Sempre inicializar o middleware** antes de usar:
```javascript
AuthMiddleware.initSupabase(supabaseClient);
```

2. **Use guards nas páginas protegidas**:
```javascript
await AuthMiddleware.requireAdmin(); // ou requireStudent()
```

3. **Ative auto-reset de timer** em páginas admin:
```javascript
AuthMiddleware.enableAutoResetTimer();
```

4. **Trate erros adequadamente**:
```javascript
const result = await AuthMiddleware.loginStudent(email, password);
if (!result.success) {
    console.error(result.message);
}
```

5. **Valide senhas antes de atualizar**:
```javascript
const validation = AuthMiddleware.validatePasswordStrength(newPassword);
if (!validation.isValid) {
    // Mostrar erro
}
```

## 🐛 Troubleshooting

### Erro: "Supabase não inicializado"
**Solução:** Chame `AuthMiddleware.initSupabase(supabaseClient)` antes de usar qualquer função.

### Sessão expira muito rápido
**Solução:** Ative `AuthMiddleware.enableAutoResetTimer()` para reset automático.

### Redirecionamento não funciona
**Solução:** Verifique os caminhos das páginas (`/admin/login.html`, `/area-aluno.html`).

### Logs não são salvos
**Solução:** Certifique-se que a tabela `admin_logs` existe no Supabase.

---

**Auth Middleware v1.0**
CertificarCursos - 2025
