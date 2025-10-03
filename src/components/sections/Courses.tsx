import { Car, FileText, Briefcase, Clock } from 'lucide-react'

export function Courses() {
  const courses = [
    {
      icon: Car,
      title: 'Vistoria Veicular Completa',
      description: 'Aprenda técnicas avançadas de vistoria veicular',
      duration: '40 horas',
    },
    {
      icon: FileText,
      title: 'Elaboração de Laudos',
      description: 'Domine a arte de elaborar laudos técnicos profissionais',
      duration: '20 horas',
    },
    {
      icon: Briefcase,
      title: 'Perícia Judicial',
      description: 'Capacitação para atuar como perito judicial veicular',
      duration: '30 horas',
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
              className="bg-white p-8 rounded-xl shadow-lg hover:shadow-xl transition-all hover:-translate-y-1"
            >
              <course.icon className="w-12 h-12 text-primary mb-4" />
              <h3 className="text-2xl font-bold mb-3">{course.title}</h3>
              <p className="text-gray-600 mb-4">{course.description}</p>
              <div className="flex items-center text-sm text-gray-500">
                <Clock size={16} className="mr-2" />
                {course.duration}
              </div>
              <button className="mt-6 w-full bg-primary text-white py-3 rounded-lg hover:bg-blue-600 transition-colors">
                Saiba Mais
              </button>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
