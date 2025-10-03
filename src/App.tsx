import { Header } from './components/layout/Header'
import { Footer } from './components/layout/Footer'
import { Hero } from './components/sections/Hero'
import { Stats } from './components/sections/Stats'
import { Courses } from './components/sections/Courses'
import { Team } from './components/sections/Team'
import { Contact } from './components/sections/Contact'

function App() {
  return (
    <div className="min-h-screen">
      <Header />
      <main>
        <Hero />
        <Stats />
        <Courses />
        <Team />
        <Contact />
      </main>
      <Footer />
    </div>
  )
}

export default App
