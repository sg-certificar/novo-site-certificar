// Configuração do Supabase
const SUPABASE_URL = 'https://jfgnelowaaiwuzwelbot.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmZ25lbG93YWFpd3V6d2VsYm90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2NjU4OTYsImV4cCI6MjA3NTI0MTg5Nn0.xp9ypKx0mtbHjs-TGinWSKqebua8Bcx9hwYKVE_UA2Y';

const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Credenciais Admin
const ADMIN_EMAIL = 'admin@certificar.app.br';
const ADMIN_PASSWORD = 'EscolaAdmin2024!';

// Session timeout (30 minutos)
const SESSION_TIMEOUT = 30 * 60 * 1000;
let sessionTimer;

// ========== AUTENTICAÇÃO ==========

function checkAuth() {
    const session = localStorage.getItem('admin_session');
    const sessionTime = localStorage.getItem('admin_session_time');

    if (!session || !sessionTime) {
        if (window.location.pathname !== '/admin/login.html') {
            window.location.href = '/admin/login.html';
        }
        return false;
    }

    const elapsed = Date.now() - parseInt(sessionTime);

    if (elapsed >= SESSION_TIMEOUT) {
        clearSession();
        alert('Sessão expirada. Faça login novamente.');
        window.location.href = '/admin/login.html';
        return false;
    }

    return true;
}

function clearSession() {
    localStorage.removeItem('admin_session');
    localStorage.removeItem('admin_session_time');
    if (sessionTimer) {
        clearInterval(sessionTimer);
    }
}

function resetSessionTimer() {
    localStorage.setItem('admin_session_time', Date.now().toString());
}

function startSessionTimer() {
    sessionTimer = setInterval(() => {
        const sessionTime = localStorage.getItem('admin_session_time');
        if (sessionTime) {
            const elapsed = Date.now() - parseInt(sessionTime);
            if (elapsed >= SESSION_TIMEOUT) {
                alert('Sessão expirada por inatividade.');
                handleLogout();
            }
        }
    }, 60000); // Verificar a cada minuto
}

async function handleLogin(event) {
    event.preventDefault();

    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const btnLogin = document.getElementById('btnLogin');
    const alert = document.getElementById('alert');

    btnLogin.disabled = true;
    btnLogin.textContent = 'Entrando...';

    // Delay de segurança
    await new Promise(resolve => setTimeout(resolve, 800));

    try {
        if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
            // Login bem-sucedido
            const sessionData = {
                email: email,
                loginTime: Date.now(),
                role: 'admin'
            };

            localStorage.setItem('admin_session', JSON.stringify(sessionData));
            localStorage.setItem('admin_session_time', Date.now().toString());

            // Log de acesso
            await logAdminAccess(email, 'login_success');

            showAlertMessage(alert, 'Login realizado com sucesso!', 'success');

            setTimeout(() => {
                window.location.href = '/admin/index.html';
            }, 1000);

        } else {
            await logAdminAccess(email, 'login_failed');
            btnLogin.disabled = false;
            btnLogin.textContent = 'Entrar no Painel';
            showAlertMessage(alert, 'Email ou senha incorretos.', 'error');
        }

    } catch (err) {
        console.error('Erro no login:', err);
        btnLogin.disabled = false;
        btnLogin.textContent = 'Entrar no Painel';
        showAlertMessage(alert, 'Erro ao fazer login.', 'error');
    }
}

function handleLogout() {
    clearSession();
    window.location.href = '/admin/login.html';
}

async function logAdminAccess(email, action) {
    try {
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

// ========== NAVEGAÇÃO ==========

function showSection(sectionName) {
    // Esconder todas as seções
    document.querySelectorAll('.section').forEach(section => {
        section.classList.remove('active');
    });

    // Remover active dos menu items
    document.querySelectorAll('.menu-item').forEach(item => {
        item.classList.remove('active');
    });

    // Mostrar seção selecionada
    const section = document.getElementById(sectionName);
    if (section) {
        section.classList.add('active');
    }

    // Marcar menu item como active
    event.target.classList.add('active');

    // Atualizar título
    const titles = {
        'dashboard': 'Dashboard',
        'cursos': 'Gestão de Cursos',
        'alunos': 'Gestão de Alunos',
        'materiais': 'Gestão de Materiais'
    };
    const titleElement = document.getElementById('pageTitle');
    if (titleElement) {
        titleElement.textContent = titles[sectionName] || 'Admin';
    }

    // Carregar dados específicos
    if (sectionName === 'cursos') {
        loadCursos();
    } else if (sectionName === 'alunos') {
        loadAlunos();
    } else if (sectionName === 'materiais') {
        loadMateriais();
    }

    // Fechar sidebar em mobile
    if (window.innerWidth <= 768) {
        document.getElementById('sidebar')?.classList.remove('open');
    }
}

function toggleSidebar() {
    document.getElementById('sidebar')?.classList.toggle('open');
}

// ========== DASHBOARD ==========

async function loadDashboardData() {
    try {
        const [alunos, materiais, cursos] = await Promise.all([
            supabaseClient.from('profiles').select('*', { count: 'exact' }),
            supabaseClient.from('materiais').select('*', { count: 'exact' }),
            supabaseClient.from('cursos').select('*', { count: 'exact' })
        ]);

        const totalAlunosEl = document.getElementById('totalAlunos');
        const totalMateriaisEl = document.getElementById('totalMateriais');
        const totalCursosEl = document.getElementById('totalCursos');

        if (totalAlunosEl) totalAlunosEl.textContent = alunos.count || 0;
        if (totalMateriaisEl) totalMateriaisEl.textContent = materiais.count || 0;
        if (totalCursosEl) totalCursosEl.textContent = cursos.count || 0;

    } catch (err) {
        console.error('Erro ao carregar dados do dashboard:', err);
    }
}

// ========== GESTÃO DE CURSOS ==========

async function loadCursos() {
    const container = document.getElementById('cursosTable');
    if (!container) return;

    container.innerHTML = '<tr><td colspan="4" style="text-align:center;">Carregando...</td></tr>';

    try {
        const { data: cursos, error } = await supabaseClient
            .from('cursos')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;

        if (!cursos || cursos.length === 0) {
            container.innerHTML = '<tr><td colspan="4" style="text-align:center;">Nenhum curso cadastrado</td></tr>';
            return;
        }

        const html = cursos.map(curso => `
            <tr>
                <td>
                    <strong>${curso.titulo}</strong><br>
                    <small style="color: #64748b;">${curso.descricao || ''}</small>
                </td>
                <td>${curso.carga_horaria || '-'}</td>
                <td>${curso.duracao_meses ? curso.duracao_meses + ' meses' : '-'}</td>
                <td>
                    <button class="btn btn-primary" onclick="editarCurso('${curso.id}')" style="padding: 6px 12px; font-size: 12px; margin-right: 5px;">
                        Editar
                    </button>
                    <button class="btn btn-danger" onclick="deletarCurso('${curso.id}')" style="padding: 6px 12px; font-size: 12px;">
                        Deletar
                    </button>
                </td>
            </tr>
        `).join('');

        container.innerHTML = html;

    } catch (err) {
        console.error('Erro ao carregar cursos:', err);
        container.innerHTML = '<tr><td colspan="4" style="text-align:center; color: #ef4444;">Erro ao carregar cursos</td></tr>';
    }
}

async function criarCurso(event) {
    event.preventDefault();

    const titulo = document.getElementById('cursoTitulo').value.trim();
    const descricao = document.getElementById('cursoDescricao').value.trim();
    const cargaHoraria = document.getElementById('cursoCargaHoraria').value.trim();
    const duracao = document.getElementById('cursoDuracao').value;
    const alert = document.getElementById('cursoAlert');
    const btn = event.target.querySelector('button[type="submit"]');

    if (!titulo || !descricao || !cargaHoraria) {
        showAlertMessage(alert, 'Preencha todos os campos obrigatórios.', 'error');
        return;
    }

    btn.disabled = true;
    btn.textContent = 'Criando...';

    try {
        const { error } = await supabaseClient
            .from('cursos')
            .insert({
                titulo: titulo,
                descricao: descricao,
                carga_horaria: cargaHoraria,
                duracao_meses: duracao ? parseInt(duracao) : null
            });

        if (error) throw error;

        showAlertMessage(alert, 'Curso criado com sucesso!', 'success');

        // Limpar formulário
        event.target.reset();

        // Recarregar lista
        await loadCursos();
        await loadCursosOptions();

    } catch (err) {
        console.error('Erro ao criar curso:', err);
        showAlertMessage(alert, 'Erro ao criar curso.', 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = 'Criar Curso';
    }
}

async function editarCurso(id) {
    try {
        // Buscar dados do curso
        const { data: curso, error } = await supabaseClient
            .from('cursos')
            .select('*')
            .eq('id', id)
            .single();

        if (error) throw error;

        // Preencher formulário com dados do curso
        const titulo = prompt('Título do Curso:', curso.titulo);
        if (!titulo) return;

        const descricao = prompt('Descrição:', curso.descricao);
        if (!descricao) return;

        const cargaHoraria = prompt('Carga Horária:', curso.carga_horaria);
        if (!cargaHoraria) return;

        const duracao = prompt('Duração (meses):', curso.duracao_meses || '');

        // Atualizar curso
        const { error: updateError } = await supabaseClient
            .from('cursos')
            .update({
                titulo: titulo,
                descricao: descricao,
                carga_horaria: cargaHoraria,
                duracao_meses: duracao ? parseInt(duracao) : null
            })
            .eq('id', id);

        if (updateError) throw updateError;

        alert('Curso atualizado com sucesso!');
        await loadCursos();
        await loadCursosOptions();

    } catch (err) {
        console.error('Erro ao editar curso:', err);
        alert('Erro ao editar curso.');
    }
}

async function deletarCurso(id) {
    if (!confirm('Deseja realmente deletar este curso? Esta ação não pode ser desfeita.')) return;

    try {
        const { error } = await supabaseClient
            .from('cursos')
            .delete()
            .eq('id', id);

        if (error) throw error;

        alert('Curso deletado com sucesso!');
        await loadCursos();
        await loadCursosOptions();

    } catch (err) {
        console.error('Erro ao deletar curso:', err);
        alert('Erro ao deletar curso. Verifique se não há alunos ou materiais vinculados.');
    }
}

// ========== GESTÃO DE ALUNOS ==========

async function loadAlunos() {
    const container = document.getElementById('alunosTable');
    if (!container) return;

    container.innerHTML = '<tr><td colspan="5" style="text-align:center;">Carregando...</td></tr>';

    try {
        const { data: emailsAutorizados, error } = await supabaseClient
            .from('emails_autorizados')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;

        if (!emailsAutorizados || emailsAutorizados.length === 0) {
            container.innerHTML = '<tr><td colspan="5" style="text-align:center;">Nenhum aluno autorizado</td></tr>';
            return;
        }

        const html = emailsAutorizados.map(item => `
            <tr>
                <td>${item.email}</td>
                <td>${item.nome_completo || '-'}</td>
                <td>
                    <code style="background: #f1f5f9; padding: 4px 8px; border-radius: 4px; font-family: monospace;">
                        ${item.codigo_gerado || '-'}
                    </code>
                </td>
                <td><span class="badge ${item.autorizado ? 'badge-success' : 'badge-warning'}">
                    ${item.autorizado ? 'Autorizado' : 'Pendente'}
                </span></td>
                <td>
                    <button class="btn btn-danger" onclick="removerAluno('${item.id}')" style="padding: 6px 12px; font-size: 12px;">
                        Remover
                    </button>
                </td>
            </tr>
        `).join('');

        container.innerHTML = html;

    } catch (err) {
        console.error('Erro ao carregar alunos:', err);
        container.innerHTML = '<tr><td colspan="5" style="text-align:center; color: #ef4444;">Erro ao carregar alunos</td></tr>';
    }
}

async function autorizarAluno(event) {
    event.preventDefault();

    const email = document.getElementById('alunoEmail').value.trim();
    const cursoId = document.getElementById('alunoCurso').value;
    const alert = document.getElementById('alunoAlert');
    const btn = event.target.querySelector('button[type="submit"]');

    if (!email || !cursoId) {
        showAlertMessage(alert, 'Preencha todos os campos.', 'error');
        return;
    }

    btn.disabled = true;
    btn.textContent = 'Autorizando...';

    try {
        // Gerar código de acesso automático
        const codigo = gerarCodigoAcesso();

        // Inserir email autorizado
        const { error: emailError } = await supabaseClient
            .from('emails_autorizados')
            .insert({
                email: email.toLowerCase(),
                curso_id: cursoId,
                autorizado: true,
                codigo_gerado: codigo
            });

        if (emailError) throw emailError;

        // Inserir código de acesso
        const { error: codigoError } = await supabaseClient
            .from('codigos_acesso')
            .insert({
                codigo: codigo,
                curso_id: cursoId,
                email_vinculado: email.toLowerCase(),
                ativo: true,
                usado: false
            });

        if (codigoError) throw codigoError;

        showAlertMessage(alert, `Aluno autorizado com sucesso! Código gerado: ${codigo}`, 'success');

        // Limpar formulário
        document.getElementById('alunoEmail').value = '';
        document.getElementById('alunoCurso').value = '';

        // Recarregar lista
        await loadAlunos();

    } catch (err) {
        console.error('Erro ao autorizar aluno:', err);
        showAlertMessage(alert, 'Erro ao autorizar aluno: ' + err.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = 'Autorizar Aluno';
    }
}

function gerarCodigoAcesso() {
    const caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let codigo = '';
    for (let i = 0; i < 8; i++) {
        codigo += caracteres.charAt(Math.floor(Math.random() * caracteres.length));
    }
    return codigo;
}

async function removerAluno(id) {
    if (!confirm('Deseja realmente remover este aluno?')) return;

    try {
        const { error } = await supabaseClient
            .from('emails_autorizados')
            .delete()
            .eq('id', id);

        if (error) throw error;

        alert('Aluno removido com sucesso!');
        await loadAlunos();

    } catch (err) {
        console.error('Erro ao remover aluno:', err);
        alert('Erro ao remover aluno.');
    }
}

function buscarAluno() {
    const searchTerm = document.getElementById('searchAluno').value.toLowerCase();
    const rows = document.querySelectorAll('#alunosTable tr');

    rows.forEach(row => {
        const email = row.cells[0]?.textContent.toLowerCase() || '';
        const nome = row.cells[1]?.textContent.toLowerCase() || '';

        if (email.includes(searchTerm) || nome.includes(searchTerm)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}

// ========== GESTÃO DE MATERIAIS ==========

async function loadMateriais() {
    const container = document.getElementById('materiaisTable');
    if (!container) return;

    container.innerHTML = '<tr><td colspan="5" style="text-align:center;">Carregando...</td></tr>';

    try {
        const { data: materiais, error } = await supabaseClient
            .from('materiais')
            .select('*, cursos(titulo)')
            .order('created_at', { ascending: false });

        if (error) throw error;

        if (!materiais || materiais.length === 0) {
            container.innerHTML = '<tr><td colspan="5" style="text-align:center;">Nenhum material cadastrado</td></tr>';
            return;
        }

        const html = materiais.map(item => `
            <tr>
                <td>${item.titulo}</td>
                <td>${item.cursos?.titulo || '-'}</td>
                <td>${item.modulo || '-'}</td>
                <td>${item.tipo || '-'}</td>
                <td>
                    <button class="btn btn-danger" onclick="deletarMaterial('${item.id}')" style="padding: 6px 12px; font-size: 12px;">
                        Deletar
                    </button>
                </td>
            </tr>
        `).join('');

        container.innerHTML = html;

    } catch (err) {
        console.error('Erro ao carregar materiais:', err);
        container.innerHTML = '<tr><td colspan="5" style="text-align:center; color: #ef4444;">Erro ao carregar materiais</td></tr>';
    }
}

async function uploadMaterial(event) {
    event.preventDefault();

    const cursoId = document.getElementById('materialCurso').value;
    const modulo = document.getElementById('materialModulo').value.trim();
    const titulo = document.getElementById('materialTitulo').value.trim();
    const fileInput = document.getElementById('materialFile');
    const file = fileInput.files[0];
    const alert = document.getElementById('materialAlert');
    const btn = event.target.querySelector('button[type="submit"]');

    if (!cursoId || !modulo || !titulo || !file) {
        showAlertMessage(alert, 'Preencha todos os campos e selecione um arquivo.', 'error');
        return;
    }

    btn.disabled = true;
    btn.textContent = 'Fazendo upload...';

    try {
        // Upload para Storage
        const fileName = `${Date.now()}_${file.name}`;
        const filePath = `${cursoId}/${modulo}/${fileName}`;

        const { error: uploadError } = await supabaseClient
            .storage
            .from('course-materials')
            .upload(filePath, file);

        if (uploadError) throw uploadError;

        // Salvar metadados no banco
        const { error: dbError } = await supabaseClient
            .from('materiais')
            .insert({
                curso_id: cursoId,
                modulo: modulo,
                titulo: titulo,
                tipo: getFileType(file.name),
                storage_path: filePath,
                tamanho: formatFileSize(file.size)
            });

        if (dbError) throw dbError;

        showAlertMessage(alert, 'Material enviado com sucesso!', 'success');

        // Limpar formulário
        event.target.reset();

        // Recarregar lista
        await loadMateriais();

    } catch (err) {
        console.error('Erro ao fazer upload:', err);
        showAlertMessage(alert, 'Erro ao enviar material.', 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = 'Enviar Material';
    }
}

async function deletarMaterial(id) {
    if (!confirm('Deseja realmente deletar este material?')) return;

    try {
        // Buscar material para obter storage_path
        const { data: material } = await supabaseClient
            .from('materiais')
            .select('storage_path')
            .eq('id', id)
            .single();

        if (material && material.storage_path) {
            // Deletar do Storage
            await supabaseClient
                .storage
                .from('course-materials')
                .remove([material.storage_path]);
        }

        // Deletar do banco
        const { error } = await supabaseClient
            .from('materiais')
            .delete()
            .eq('id', id);

        if (error) throw error;

        alert('Material deletado com sucesso!');
        await loadMateriais();

    } catch (err) {
        console.error('Erro ao deletar material:', err);
        alert('Erro ao deletar material.');
    }
}

// ========== UTILITÁRIOS ==========

function showAlertMessage(element, message, type) {
    if (!element) return;

    element.textContent = message;
    element.className = `alert alert-${type}`;
    element.style.display = 'block';

    setTimeout(() => {
        element.style.display = 'none';
    }, 5000);
}

function getFileType(fileName) {
    const ext = fileName.split('.').pop().toLowerCase();
    const types = {
        'pdf': 'pdf',
        'mp4': 'video',
        'avi': 'video',
        'mov': 'video',
        'doc': 'documento',
        'docx': 'documento',
        'ppt': 'apresentacao',
        'pptx': 'apresentacao'
    };
    return types[ext] || 'arquivo';
}

function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

async function loadCursosOptions() {
    try {
        const { data: cursos } = await supabaseClient
            .from('cursos')
            .select('id, titulo')
            .order('titulo');

        if (cursos) {
            const selects = document.querySelectorAll('#alunoCurso, #materialCurso');
            selects.forEach(select => {
                if (select) {
                    select.innerHTML = '<option value="">Selecione um curso</option>' +
                        cursos.map(c => `<option value="${c.id}">${c.titulo}</option>`).join('');
                }
            });
        }
    } catch (err) {
        console.error('Erro ao carregar cursos:', err);
    }
}

// Drag & Drop
function setupDragDrop() {
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('materialFile');

    if (!uploadArea || !fileInput) return;

    uploadArea.addEventListener('click', () => fileInput.click());

    uploadArea.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadArea.classList.add('dragover');
    });

    uploadArea.addEventListener('dragleave', () => {
        uploadArea.classList.remove('dragover');
    });

    uploadArea.addEventListener('drop', (e) => {
        e.preventDefault();
        uploadArea.classList.remove('dragover');

        const files = e.dataTransfer.files;
        if (files.length > 0) {
            fileInput.files = files;
            uploadArea.querySelector('.upload-text').textContent = files[0].name;
        }
    });

    fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
            uploadArea.querySelector('.upload-text').textContent = e.target.files[0].name;
        }
    });
}

// ========== INICIALIZAÇÃO ==========

document.addEventListener('DOMContentLoaded', () => {
    // Reset session timer em atividades
    document.addEventListener('click', resetSessionTimer);
    document.addEventListener('keypress', resetSessionTimer);
});
