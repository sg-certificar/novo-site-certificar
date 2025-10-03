import { Users, Award, Calendar } from 'lucide-react'

export function Stats() {
  const stats = [
    { icon: Users, value: '500+', label: 'Alunos Formados' },
    { icon: Award, value: '100%', label: 'Certificação Nacional' },
    { icon: Calendar, value: '15', label: 'Anos de Experiência' },
  ]

  return (
    <section className="py-16 bg-gray-50">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {stats.map((stat, index) => (
            <div key={index} className="text-center">
              <stat.icon className="w-12 h-12 mx-auto mb-4 text-primary" />
              <div className="text-4xl font-bold text-dark mb-2">{stat.value}</div>
              <div className="text-gray-600">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
