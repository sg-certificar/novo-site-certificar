import { ArrowRight } from 'lucide-react'

export function Hero() {
  return (
    <section id="inicio" className="relative bg-gradient-to-br from-primary to-blue-600 text-white py-20 md:py-32">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl">
          <div className="inline-block bg-accent px-4 py-2 rounded-full text-sm font-semibold mb-6">
            Próxima turma: 27 e 28 de Outubro
          </div>

          <h1 className="text-4xl md:text-6xl font-bold mb-6">
            Especialistas em Formação de Vistoriadores Veiculares
          </h1>

          <p className="text-xl md:text-2xl mb-8 text-blue-100">
            Seja um profissional certificado e inicie uma carreira promissora
          </p>

          <button className="bg-accent hover:bg-orange-600 text-white px-8 py-4 rounded-lg text-lg font-semibold flex items-center gap-2 transition-all">
            Inscreva-se Agora
            <ArrowRight size={20} />
          </button>
        </div>
      </div>
    </section>
  )
}
