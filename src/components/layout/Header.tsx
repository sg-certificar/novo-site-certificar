import { useState } from 'react'
import { Menu, X } from 'lucide-react'

export function Header() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-white/80 backdrop-blur-sm">
      <nav className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <img
            src="/static/images/logo-certificar-transparent.png"
            alt="Certificar"
            className="h-12 w-auto"
          />

          {/* Desktop Menu */}
          <div className="hidden md:flex items-center gap-8">
            <a href="#inicio" className="hover:text-primary transition-colors">Início</a>
            <a href="#cursos" className="hover:text-primary transition-colors">Cursos</a>
            <a href="#equipe" className="hover:text-primary transition-colors">Equipe</a>
            <a href="#contato" className="hover:text-primary transition-colors">Contato</a>

            <div className="flex items-center gap-2">
              <a href="#talentos" className="text-gray-400 cursor-not-allowed">
                Banco de Talentos
                <span className="ml-2 text-xs bg-gray-200 px-2 py-1 rounded">Em Breve</span>
              </a>
            </div>

            <a
              href="/area-aluno.html"
              className="bg-primary text-white px-4 py-2 rounded-lg hover:bg-[#2563eb] transition-colors"
            >
              Área do Aluno
            </a>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden"
            onClick={() => setIsOpen(!isOpen)}
          >
            {isOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isOpen && (
          <div className="md:hidden mt-4 pb-4 space-y-4">
            <a href="#inicio" className="block hover:text-primary">Início</a>
            <a href="#cursos" className="block hover:text-primary">Cursos</a>
            <a href="#equipe" className="block hover:text-primary">Equipe</a>
            <a href="#contato" className="block hover:text-primary">Contato</a>
            <div className="text-gray-400">Banco de Talentos <span className="text-xs">(Em Breve)</span></div>
            <a href="/area-aluno.html" className="block text-primary font-semibold">Área do Aluno</a>
          </div>
        )}
      </nav>
    </header>
  )
}
