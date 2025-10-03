import { Mail, Phone, MapPin } from 'lucide-react'

export function Contact() {
  return (
    <section id="contato" className="py-20">
      <div className="container mx-auto px-4">
        <h2 className="text-4xl font-bold text-center mb-12">Entre em Contato</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 max-w-5xl mx-auto">
          <div>
            <h3 className="text-2xl font-bold mb-6">Informações de Contato</h3>

            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <Phone className="text-primary mt-1" />
                <div>
                  <p className="font-semibold">Telefone</p>
                  <p className="text-gray-600">(11) 93082-8447</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Mail className="text-primary mt-1" />
                <div>
                  <p className="font-semibold">Email</p>
                  <p className="text-gray-600">contato@certificarcursos.com.br</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <MapPin className="text-primary mt-1" />
                <div>
                  <p className="font-semibold">Endereço</p>
                  <p className="text-gray-600">Santo André - SP</p>
                </div>
              </div>
            </div>
          </div>

          <form
            action="https://formspree.io/f/xjkwgowo"
            method="POST"
            className="space-y-4"
          >
            <input
              type="text"
              name="nome"
              placeholder="Nome"
              required
              className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-primary focus:outline-none"
            />
            <input
              type="email"
              name="email"
              placeholder="Email"
              required
              className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-primary focus:outline-none"
            />
            <input
              type="tel"
              name="telefone"
              placeholder="Telefone"
              className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-primary focus:outline-none"
            />
            <textarea
              name="mensagem"
              placeholder="Mensagem"
              rows={4}
              required
              className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-primary focus:outline-none"
            ></textarea>
            <button
              type="submit"
              className="w-full bg-primary text-white py-3 rounded-lg hover:bg-blue-600 transition-colors font-semibold"
            >
              Enviar Mensagem
            </button>
          </form>
        </div>
      </div>
    </section>
  )
}
