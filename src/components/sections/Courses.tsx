import { Car, Briefcase, Shield, Clock, Calendar } from 'lucide-react'

export function Courses() {
  const courses = [
    {
      icon: Car,
      badge: 'Próxima Turma',
      title: 'Curso Básico',
      subtitle: 'Vistoriador Veicular',
      hours: '40 horas',
      schedule: '27 e 28 de outubro de 2025',
      certificate: 'Certificado',
      cta: 'Ver Planos',
      status: 'EM BREVE'
    },
    {
      icon: Briefcase,
      title: 'Curso Avançado',
      subtitle: 'Perícia Veicular',
      hours: '80 horas',
      schedule: 'Turmas bimestrais',
      certificate: 'Certificado',
      cta: 'Ver Planos',
      status: 'EM BREVE'
    },
    {
      icon: Shield,
      title: 'Especialização',
      subtitle: 'Detecção de Fraudes',
      hours: '60 horas',
      schedule: 'Turmas trimestrais',
      certificate: 'Certificado',
      cta: 'Ver Planos',
      status: ''
    },
  ]

  return (
    <section id="cursos" className="py-20">
      <div className="container mx-auto px-4">
        <h2 className="text-4xl font-bold text-center mb-4">Nossos Cursos</h2>
        <p className="text-xl text-gray-600 text-center mb-12">
          Formação completa para vistoriadores veiculares
        </p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {courses.map((course, index) => (
            <div
              key={index}
              className="bg-white p-8 rounded-xl shadow-lg hover:shadow-xl transition-all hover:-translate-y-1 relative"
            >
              {course.badge && (
                <span className="absolute top-4 right-4 bg-accent text-white text-xs px-3 py-1 rounded-full">
                  {course.badge}
                </span>
              )}

              <course.icon className="w-12 h-12 text-primary mb-4" />
              <h3 className="text-2xl font-bold mb-2">{course.title}</h3>
              <p className="text-lg text-primary font-semibold mb-4">{course.subtitle}</p>

              <div className="space-y-2 mb-6">
                <div className="flex items-center text-gray-600">
                  <Clock size={16} className="mr-2" />
                  {course.hours}
                </div>
                <div className="flex items-center text-gray-600">
                  <Calendar size={16} className="mr-2" />
                  {course.schedule}
                </div>
                <div className="text-success font-semibold">
                  ✓ {course.certificate}
                </div>
              </div>

              <button className="w-full bg-primary text-white py-3 rounded-lg hover:bg-blue-600 transition-colors font-semibold">
                {course.cta}
              </button>

              {course.status && (
                <div className="text-center mt-3 text-sm text-gray-500 font-semibold">
                  {course.status}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
