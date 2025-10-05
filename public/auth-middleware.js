/**
 * Auth Middleware - Sistema de Autenticação Compartilhado
 * CertificarCursos - 2025
 *
 * Funções compartilhadas para autenticação de admin e alunos
 */

// Configuração do Supabase (será inicializado externamente)
let supabaseClient = null;

// Configurações
const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutos
const ADMIN_EMAIL = 'admin@certificar.app.br';
const ADMIN_PASSWORD = 'EscolaAdmin2024!';

// Timers
let sessionTimer = null;

/**
 * Inicializar Supabase Client
 * Deve ser chamado antes de usar qualquer função
 */
function initSupabase(client) {
    supabaseClient = client;
}

// ========== VERIFICAÇÕES DE AUTENTICAÇÃO ==========

/**
 * Verifica se usuário atual é admin válido
 * @returns {Promise<boolean>} true se for admin autenticado
 */
async function checkAdminAuth() {
    try {
        const session = localStorage.getItem('admin_session');
        const sessionTime = localStorage.getItem('admin_session_time');

        if (!session || !sessionTime) {
            return false;
        }

        // Verificar timeout
        const elapsed = Date.now() - parseInt(sessionTime);
        if (elapsed >= SESSION_TIMEOUT) {
            clearAdminSession();
            return false;
        }

        // Verificar se é admin válido
        const sessionData = JSON.parse(session);
        if (sessionData.role !== 'admin') {
            return false;
        }

        // Sessão válida
        resetSessionTimer();
        return true;

    } catch (err) {
        console.error('Erro ao verificar auth admin:', err);
        return false;
    }
}

/**
 * Verifica se usuário atual é aluno autenticado
 * @returns {Promise<boolean>} true se for aluno autenticado
 */
async function checkStudentAuth() {
    try {
        if (!supabaseClient) {
            console.error('Supabase não inicializado');
            return false;
        }

        const { data: { session } } = await supabaseClient.auth.getSession();

        if (!session || !session.user) {
            return false;
        }

        // Verificar se email está autorizado (opcional)
        const { data: emailAutorizado } = await supabaseClient
            .from('emails_autorizados')
            .select('*')
            .eq('email', session.user.email.toLowerCase())
            .eq('autorizado', true)
            .single();

        return !!emailAutorizado;

    } catch (err) {
        console.error('Erro ao verificar auth aluno:', err);
        return false;
    }
}

/**
 * Obtém dados do usuário atual
 * @returns {Object|null} Dados do usuário ou null
 */
async function getCurrentUser() {
    try {
        // Verificar se é admin
        const adminSession = localStorage.getItem('admin_session');
        if (adminSession) {
            return {
                type: 'admin',
                data: JSON.parse(adminSession)
            };
        }

        // Verificar se é aluno
        if (supabaseClient) {
            const { data: { session } } = await supabaseClient.auth.getSession();
            if (session && session.user) {
                return {
                    type: 'student',
                    data: session.user
                };
            }
        }

        return null;

    } catch (err) {
        console.error('Erro ao obter usuário atual:', err);
        return null;
    }
}

// ========== REDIRECIONAMENTOS ==========

/**
 * Redireciona para login apropriado
 * @param {string} userType - 'admin' ou 'student'
 * @param {string} message - Mensagem opcional
 */
function redirectToLogin(userType = 'student', message = '') {
    if (message) {
        sessionStorage.setItem('login_message', message);
    }

    if (userType === 'admin') {
        window.location.href = '/admin/login.html';
    } else {
        window.location.href = '/area-aluno.html';
    }
}

/**
 * Redireciona para dashboard apropriado
 * @param {string} userType - 'admin' ou 'student'
 */
function redirectToDashboard(userType = 'student') {
    if (userType === 'admin') {
        window.location.href = '/admin/index.html';
    } else {
        window.location.href = '/area-aluno.html';
    }
}

// ========== LOGIN ==========

/**
 * Login de Admin
 * @param {string} email - Email do admin
 * @param {string} password - Senha do admin
 * @returns {Promise<Object>} Resultado do login
 */
async function loginAdmin(email, password) {
    try {
        // Delay de segurança
        await new Promise(resolve => setTimeout(resolve, 800));

        if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
            const sessionData = {
                email: email,
                loginTime: Date.now(),
                role: 'admin'
            };

            localStorage.setItem('admin_session', JSON.stringify(sessionData));
            localStorage.setItem('admin_session_time', Date.now().toString());

            // Log de acesso
            if (supabaseClient) {
                await logAccess(email, 'admin_login_success');
            }

            startAdminSessionTimer();

            return { success: true, message: 'Login realizado com sucesso!' };
        } else {
            if (supabaseClient) {
                await logAccess(email, 'admin_login_failed');
            }

            return { success: false, message: 'Email ou senha incorretos.' };
        }

    } catch (err) {
        console.error('Erro no login admin:', err);
        return { success: false, message: 'Erro ao fazer login.' };
    }
}

/**
 * Login de Aluno via Supabase Auth
 * @param {string} email - Email do aluno
 * @param {string} password - Senha do aluno
 * @returns {Promise<Object>} Resultado do login
 */
async function loginStudent(email, password) {
    try {
        if (!supabaseClient) {
            throw new Error('Supabase não inicializado');
        }

        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email: email,
            password: password
        });

        if (error) {
            await logAccess(email, 'student_login_failed');
            return { success: false, message: error.message };
        }

        await logAccess(email, 'student_login_success');

        return { success: true, message: 'Login realizado com sucesso!', user: data.user };

    } catch (err) {
        console.error('Erro no login aluno:', err);
        return { success: false, message: 'Erro ao fazer login.' };
    }
}

// ========== LOGOUT ==========

/**
 * Logout universal (admin ou aluno)
 * @param {string} userType - 'admin' ou 'student'
 */
async function logout(userType = null) {
    try {
        // Detectar tipo automaticamente se não fornecido
        if (!userType) {
            const user = await getCurrentUser();
            userType = user?.type || 'student';
        }

        if (userType === 'admin') {
            clearAdminSession();
            if (sessionTimer) {
                clearInterval(sessionTimer);
            }
            redirectToLogin('admin', 'Logout realizado com sucesso.');
        } else {
            if (supabaseClient) {
                await supabaseClient.auth.signOut();
            }
            redirectToLogin('student', 'Logout realizado com sucesso.');
        }

    } catch (err) {
        console.error('Erro ao fazer logout:', err);
        // Forçar redirecionamento mesmo com erro
        if (userType === 'admin') {
            clearAdminSession();
            window.location.href = '/admin/login.html';
        } else {
            window.location.href = '/area-aluno.html';
        }
    }
}

// ========== RECUPERAÇÃO DE SENHA ==========

/**
 * Enviar email de recuperação de senha
 * @param {string} email - Email do usuário
 * @returns {Promise<Object>} Resultado da operação
 */
async function resetPassword(email) {
    try {
        if (!supabaseClient) {
            throw new Error('Supabase não inicializado');
        }

        const { error } = await supabaseClient.auth.resetPasswordForEmail(email, {
            redirectTo: `${window.location.origin}/area-aluno.html`
        });

        if (error) {
            return { success: false, message: error.message };
        }

        await logAccess(email, 'password_reset_requested');

        return {
            success: true,
            message: 'Email de recuperação enviado! Verifique sua caixa de entrada.'
        };

    } catch (err) {
        console.error('Erro ao solicitar recuperação:', err);
        return { success: false, message: 'Erro ao solicitar recuperação de senha.' };
    }
}

/**
 * Atualizar senha do usuário logado
 * @param {string} newPassword - Nova senha
 * @param {string} currentPassword - Senha atual (opcional, para validação)
 * @returns {Promise<Object>} Resultado da operação
 */
async function updatePassword(newPassword, currentPassword = null) {
    try {
        if (!supabaseClient) {
            throw new Error('Supabase não inicializado');
        }

        // Validar senha atual se fornecida
        if (currentPassword) {
            const { data: { user } } = await supabaseClient.auth.getUser();
            if (user) {
                // Tentar fazer login com senha atual para validar
                const { error: loginError } = await supabaseClient.auth.signInWithPassword({
                    email: user.email,
                    password: currentPassword
                });

                if (loginError) {
                    return { success: false, message: 'Senha atual incorreta.' };
                }
            }
        }

        // Atualizar senha
        const { error } = await supabaseClient.auth.updateUser({
            password: newPassword
        });

        if (error) {
            return { success: false, message: error.message };
        }

        const { data: { user } } = await supabaseClient.auth.getUser();
        if (user) {
            await logAccess(user.email, 'password_updated');
        }

        return { success: true, message: 'Senha atualizada com sucesso!' };

    } catch (err) {
        console.error('Erro ao atualizar senha:', err);
        return { success: false, message: 'Erro ao atualizar senha.' };
    }
}

// ========== SESSION MANAGEMENT ==========

/**
 * Limpar sessão de admin
 */
function clearAdminSession() {
    localStorage.removeItem('admin_session');
    localStorage.removeItem('admin_session_time');
}

/**
 * Reset do timer de sessão
 */
function resetSessionTimer() {
    localStorage.setItem('admin_session_time', Date.now().toString());
}

/**
 * Iniciar timer de sessão do admin
 */
function startAdminSessionTimer() {
    if (sessionTimer) {
        clearInterval(sessionTimer);
    }

    sessionTimer = setInterval(async () => {
        const sessionTime = localStorage.getItem('admin_session_time');
        if (sessionTime) {
            const elapsed = Date.now() - parseInt(sessionTime);
            if (elapsed >= SESSION_TIMEOUT) {
                alert('Sessão expirada por inatividade.');
                await logout('admin');
            }
        }
    }, 60000); // Verificar a cada minuto
}

/**
 * Ativar reset automático de timer em atividades
 */
function enableAutoResetTimer() {
    document.addEventListener('click', resetSessionTimer);
    document.addEventListener('keypress', resetSessionTimer);
    document.addEventListener('scroll', resetSessionTimer);
}

// ========== GUARDS DE PÁGINA ==========

/**
 * Guard para páginas admin - redireciona se não for admin
 */
async function requireAdmin() {
    const isAdmin = await checkAdminAuth();
    if (!isAdmin) {
        redirectToLogin('admin', 'Acesso negado. Faça login como administrador.');
    }
    return isAdmin;
}

/**
 * Guard para páginas de aluno - redireciona se não for aluno autenticado
 */
async function requireStudent() {
    const isStudent = await checkStudentAuth();
    if (!isStudent) {
        redirectToLogin('student', 'Acesso negado. Faça login para continuar.');
    }
    return isStudent;
}

// ========== UTILITÁRIOS ==========

/**
 * Log de acessos e ações
 * @param {string} email - Email do usuário
 * @param {string} action - Ação realizada
 */
async function logAccess(email, action) {
    try {
        if (!supabaseClient) return;

        await supabaseClient.from('admin_logs').insert({
            email: email,
            action: action,
            user_agent: navigator.userAgent,
            timestamp: new Date().toISOString()
        });
    } catch (err) {
        console.error('Erro ao registrar log:', err);
    }
}

/**
 * Obter mensagem de login (se houver)
 * @returns {string|null} Mensagem ou null
 */
function getLoginMessage() {
    const message = sessionStorage.getItem('login_message');
    if (message) {
        sessionStorage.removeItem('login_message');
        return message;
    }
    return null;
}

/**
 * Verificar se senha é forte
 * @param {string} password - Senha a validar
 * @returns {Object} Resultado da validação
 */
function validatePasswordStrength(password) {
    const minLength = 6;
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    const isValid = password.length >= minLength;

    return {
        isValid: isValid,
        message: isValid ? 'Senha válida' : `Senha deve ter no mínimo ${minLength} caracteres`,
        strength: (hasUpperCase ? 1 : 0) + (hasLowerCase ? 1 : 0) + (hasNumbers ? 1 : 0) + (hasSpecialChar ? 1 : 0)
    };
}

// ========== EXPORTS ==========

// Exportar funções para uso global
if (typeof window !== 'undefined') {
    window.AuthMiddleware = {
        // Inicialização
        initSupabase,

        // Verificações
        checkAdminAuth,
        checkStudentAuth,
        getCurrentUser,

        // Redirecionamentos
        redirectToLogin,
        redirectToDashboard,

        // Login
        loginAdmin,
        loginStudent,

        // Logout
        logout,

        // Senha
        resetPassword,
        updatePassword,
        validatePasswordStrength,

        // Guards
        requireAdmin,
        requireStudent,

        // Session
        clearAdminSession,
        resetSessionTimer,
        startAdminSessionTimer,
        enableAutoResetTimer,

        // Utilitários
        getLoginMessage,
        logAccess
    };
}
