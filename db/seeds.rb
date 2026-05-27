puts "=========================================================="
puts "       Nettoyage de la base de données...                "
puts "=========================================================="

# On supprime dans l'ordre inverse des dépendances pour éviter les erreurs de clés étrangères
puts "Suppression des anciens feedbacks..."
Feedback.destroy_all if defined?(Feedback)

puts "Suppression des anciens messages..."
Message.destroy_all if defined?(Message)

puts "Suppression des anciens chats..."
Chat.destroy_all if defined?(Chat)

puts "Suppression des anciens rôles de chat..."
ChatRole.destroy_all if defined?(ChatRole)

puts "Suppression des anciens entretiens..."
Interview.destroy_all if defined?(Interview)

puts "Suppression des anciens utilisateurs..."
User.destroy_all if defined?(User)


puts "\n=========================================================="
puts "       Création des données de base                       "
puts "=========================================================="

# 1. Création d'un utilisateur de test (requis pour l'interview)
test_user = User.create!(
  email: "candidat@test.com",
  password: "password123",
  password_confirmation: "password123"
)
puts "✅ Utilisateur de test créé (candidat@test.com / password123)"

# 2. Création des rôles de chat prédéfinis
rh_role = ChatRole.create!(
  title: "RH",
  prompt_description: "Tu es un chargé de recrutement RH bienveillant mais sélectif. Ton objectif est d'évaluer la cohérence du parcours du candidat, ses motivations profondes et son adéquation culturelle (cultural fit) avec l'entreprise. Pose des questions sur sa capacité à collaborer, sa gestion du stress, ses attentes managériales et sa projection dans le poste. Adopte un ton professionnel, accueillant et encourageant. Pose une seule question à la fois."
)
manager_role = ChatRole.create!(
  title: "Manager",
  prompt_description: "Tu es le manager opérationnel de l'équipe que le candidat souhaite rejoindre. Ton objectif est d'évaluer l'autonomie, l'esprit d'initiative, la gestion des priorités et la capacité à délivrer des résultats concrets. Tu t'intéresses aux méthodologies de travail (ex: Agile), à la gestion de projet et à la communication. Adopte un ton pragmatique, orienté business, challengeant mais constructif. Pose une seule question à la fois."
)
tech_role = ChatRole.create!(
  title: "Tech",
  prompt_description: "Tu es un Lead Tech ou un Ingénieur Senior exigeant. Ton objectif est d'évaluer la profondeur des compétences techniques, la logique face à des cas complexes (troubleshooting, system design) et les bonnes pratiques de développement (Clean Code, architecture, testing). Tu analyses la façon dont le candidat structure sa pensée face à un problème. Adopte un ton factuel, technique, précis et analytique.Pose une seule question à la fois."
)
puts "✅ #{ChatRole.count} rôles de chat créés !"


puts "\n=========================================================="
puts "       Création des entretiens de simulation              "
puts "=========================================================="

# On crée des instances d'Interview directement pour notre utilisateur de test
interview_rails = Interview.create!(
  user: test_user,
  job_title: "Développeur Fullstack Ruby on Rails (H/F)",
  job_description: <<~TEXT
    En tant que développeur fullstack au sein de notre équipe produit, vos missions seront :
    - Concevoir et développer de nouvelles fonctionnalités robustes en Ruby on Rails 8.
    - Travailler sur le frontend avec Hotwire (Turbo & Stimulus) et Bootstrap.
    - Écrire des tests unitaires et d'intégration avec RSpec ou Minitest.
    - Participer aux revues de code et à l'architecture de la base de données PostgreSQL.

    Profil recherché :
    - Au moins 2 ans d'expérience sur Ruby on Rails.
    - Bonnes connaissances en base de données SQL.
    - Autonomie, esprit d'équipe et rigueur technique.
  TEXT
)

interview_pm = Interview.create!(
  user: test_user,
  job_title: "Product Manager - IA & SaaS (H/F)",
  job_description: <<~TEXT
    Rattaché(e) au Head of Product, vous prendrez la responsabilité de notre module de simulation IA.
    Vos missions :
    - Définir la roadmap produit en étroite collaboration avec les équipes tech et design.
    - Rédiger des spécifications fonctionnelles détaillées (User Stories).
    - Annuler les rituels agiles (Sprint Planning, Daily, Retrospective).

    Profil recherché :
    - Première expérience réussie en tant que PM ou Product Owner en environnement SaaS.
    - Forte sensibilité aux technologies IA (LLMs, prompt engineering).
  TEXT
)
puts "✅ #{Interview.count} simulations d'entretiens créées pour le candidat."


puts "\n=========================================================="
puts "   Création d'une conversation de test terminée           "
puts "=========================================================="

# 3. Création du chat associé à l'entretien Rails et au rôle Technique
chat_tech = Chat.create!(
  interview: interview_rails,
  chat_role: tech_role,
  title: "Entretien technique - Rails & SQL"
)

# 4. Création des messages associés au chat
Message.create!([
  { chat: chat_tech, role: "assistant", content: "Bonjour Jean, merci d'être là. Pourquoi souhaitez-vous rejoindre notre équipe en tant que Développeur Rails ?" },
  { chat: chat_tech, role: "user", content: "Bonjour ! Je suis passionné par Rails pour sa rapidité de développement, et je veux travailler sur des produits à fort impact avec une équipe structurée." },
  { chat: chat_tech, role: "assistant", content: "Très bien. Pouvez-vous me parler d'un projet récent où vous avez dû optimiser des requêtes SQL lentes dans Rails ?" },
  { chat: chat_tech, role: "user", content: "Oui, j'ai dû utiliser des inclusions (includes) pour éviter les requêtes N+1 et rajouter des index sur les clés étrangères dans PostgreSQL." }
])
puts "✅ Simulation de discussion créée (#{chat_tech.messages.count} messages)"

# 5. Création du feedback relié au chat
Feedback.create!(
  chat: chat_tech,
  global_score: 82,
  strengths: <<~MARKDOWN,
    - **Forte maîtrise technique** : Très bonne explication du cycle de vie d'un contrôleur Rails et de l'utilisation d'Active Record.
    - **Exemples concrets** : Utilisation pertinente d'exemples de projets passés pour illustrer la résolution de bugs.
  MARKDOWN
  weaknesses: <<~MARKDOWN,
    - **Précision technique** : Explications un peu floues sur la différence précise entre Turbo et Stimulus.
    - **Structure** : Attention à ne pas trop s'éparpiller sur les réponses courtes. Pense à structurer tes réponses avec la méthode STAR.
  MARKDOWN
  priority_advice: "Pour ton prochain entretien réel, prépare 2 histoires concrètes de bugs complexes que tu as résolus, en te focalisant sur tes actions individuelles.",
  recommended_method: "Méthode STAR (Situation, Tâche, Action, Résultat)",
  best_answer: "L'explication très claire de la résolution des requêtes N+1 à l'aide de `.includes`.",
  worst_answer: "La réponse sur le fonctionnement interne de Turbo Drive et Stimulus, qui manquait de précision technique."
)
puts "✅ Rapport de feedback et coaching généré pour la simulation !"

puts "\n=========================================================="
puts "           Seeding terminé avec succès !                  "
puts "=========================================================="
