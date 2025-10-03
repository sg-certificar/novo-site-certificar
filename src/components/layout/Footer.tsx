import { Facebook, Instagram, Linkedin } from 'lucide-react'

export function Footer() {
  return (
    <footer className="bg-dark text-white py-12">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <h3 className="text-2xl font-bold mb-4">CERTIFICAR</h3>
            <p className="text-gray-400">Formando profissionais de excelência</p>
          </div>

          <div>
            <h4 className="font-bold mb-4">Links</h4>
            <ul className="space-y-2 text-gray-400">
              <li><a href="#cursos" className="hover:text-white">Cursos</a></li>
              <li><a href="#equipe" className="hover:text-white">Equipe</a></li>
              <li><a href="#contato" className="hover:text-white">Contato</a></li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold mb-4">Em Breve</h4>
            <ul className="space-y-2 text-gray-400">
              <li>Banco de Talentos</li>
              <li>Área do Aluno</li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold mb-4">Redes Sociais</h4>
            <div className="flex gap-4">
              <Facebook className="cursor-pointer hover:text-primary" />
              <Instagram className="cursor-pointer hover:text-primary" />
              <Linkedin className="cursor-pointer hover:text-primary" />
            </div>
          </div>
        </div>

        <div className="border-t border-gray-700 mt-8 pt-8 text-center text-gray-400">
          <p>&copy; 2024 Certificar. Todos os direitos reservados.</p>
        </div>
      </div>
    </footer>
  )
}
