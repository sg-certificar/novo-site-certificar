export function Team() {
  const professors = [
    {
      name: 'Regis Farina',
      role: 'Coordenador e Instrutor',
      bio: 'Pós-graduado em diversas áreas: engenharia automotiva, energia e meio ambiente, química, astronomia, paleontologia e direito.',
      image: '/placeholder-regis.jpg',
    },
    {
      name: 'Michel Gonçalves Barros',
      role: 'Perito Judicial Veicular',
      bio: 'Informações detalhadas em breve',
      image: '/placeholder-michel.jpg',
    },
  ]

  return (
    <section id="equipe" className="py-20 bg-gray-50">
      <div className="container mx-auto px-4">
        <h2 className="text-4xl font-bold text-center mb-4">Nossa Equipe</h2>
        <p className="text-xl text-gray-600 text-center mb-12">
          Profissionais experientes e qualificados
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {professors.map((prof, index) => (
            <div key={index} className="bg-white p-8 rounded-xl shadow-lg text-center">
              <div className="w-32 h-32 bg-gray-300 rounded-full mx-auto mb-4"></div>
              <h3 className="text-2xl font-bold mb-2">{prof.name}</h3>
              <p className="text-primary font-semibold mb-4">{prof.role}</p>
              <p className="text-gray-600">{prof.bio}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
