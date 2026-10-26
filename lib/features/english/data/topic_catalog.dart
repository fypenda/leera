import '../domain/practice_topic.dart';
import 'topic_bank.dart';

/// The topics a session can draw, bundled with the app.
///
/// Sessions store a topic's id: never change or reuse one. A topic can be
/// added at any time; one that is removed still has to be found for the
/// sessions that drew it, which [topicById] handles.
const topicCatalog = [..._firstTopics, ...moreTopics];

/// The topics the app started with, carried over from NOURISH.
const _firstTopics = [
  PracticeTopic(
    id: 'suez-canal',
    title: 'How the Suez Canal changed world trade',
    prompt:
        'Find out who built it, why it mattered, and what happens when it '
        'closes.',
    categories: ['🏛️ History', '💰 Economy'],
    emoji: '🚢',
    outline: ['What is it?', 'Why does it matter?', 'What happened in 2021?'],
  ),
  PracticeTopic(
    id: 'great-green-wall',
    title: "Why the Sahel's Great Green Wall fell behind schedule",
    prompt:
        'Find out what the project set out to do, how far it got, and what '
        'slowed it down.',
    categories: ['🌍 Environment', '🌱 Africa'],
    emoji: '🌳',
    outline: [
      'What is the Great Green Wall?',
      'What has it achieved so far?',
      'What held it back?',
    ],
  ),
  PracticeTopic(
    id: 'vaccines',
    title: 'How vaccines train the immune system',
    prompt:
        'Find out what happens in the body after a vaccine, and why some need '
        'boosters.',
    categories: ['🔬 Science', '🩺 Health'],
    emoji: '💉',
    outline: [
      'What does a vaccine contain?',
      'How does the body respond?',
      'Why are boosters sometimes needed?',
    ],
  ),
  PracticeTopic(
    id: 'mali-empire',
    title: 'What made the Mali Empire so wealthy',
    prompt:
        'Find out where its wealth came from, and how Mansa Musa made it '
        'famous.',
    categories: ['🏛️ History', '🌱 Africa'],
    emoji: '👑',
    outline: [
      'Where and when was the Mali Empire?',
      'Where did its wealth come from?',
      'Why is Mansa Musa still remembered?',
    ],
  ),
  PracticeTopic(
    id: 'search-engines',
    title: 'How a search engine ranks pages',
    prompt: 'Find out how pages are found, indexed and ordered when you search.',
    categories: ['💻 Technology'],
    emoji: '🔎',
    outline: [
      'How are pages found?',
      'What is an index?',
      'What decides the order of results?',
    ],
  ),
  PracticeTopic(
    id: 'mobile-money',
    title: 'How mobile money changed daily life in East Africa',
    prompt:
        'Find out how M-Pesa works, why it spread so fast, and what it '
        'changed for people without a bank account.',
    categories: ['💰 Economy', '🌱 Africa', '💻 Technology'],
    emoji: '📱',
    outline: [
      'What is mobile money?',
      'Why did it spread so quickly in Kenya?',
      'What did it change for people?',
    ],
  ),
  PracticeTopic(
    id: 'printing-press',
    title: 'Why the printing press changed Europe',
    prompt:
        "Find out what Gutenberg invented, and how cheap books changed "
        'religion, science and politics.',
    categories: ['🏛️ History', '💻 Technology'],
    emoji: '📜',
    outline: [
      'What did Gutenberg invent, and when?',
      'Why were books suddenly cheaper?',
      'What changed as a result?',
    ],
  ),
  PracticeTopic(
    id: 'sleep',
    title: 'What happens in the brain while we sleep',
    prompt:
        'Find out what the stages of sleep are, and why skipping sleep '
        'affects memory.',
    categories: ['🔬 Science', '🩺 Health'],
    emoji: '😴',
    outline: [
      'What are the stages of sleep?',
      'What does the brain do at night?',
      'What happens when we sleep too little?',
    ],
  ),
  PracticeTopic(
    id: 'inflation',
    title: 'What causes inflation, and how central banks fight it',
    prompt:
        'Find out why prices rise, and how raising interest rates is meant '
        'to slow them down.',
    categories: ['💰 Economy'],
    emoji: '📈',
    outline: [
      'What is inflation?',
      'What makes prices rise?',
      'How do interest rates help?',
    ],
  ),
  PracticeTopic(
    id: 'coral-reefs',
    title: 'Why coral reefs are bleaching',
    prompt:
        'Find out what coral bleaching is, what causes it, and whether reefs '
        'can recover.',
    categories: ['🌍 Environment', '🔬 Science'],
    emoji: '🐠',
    outline: [
      'What is a coral reef made of?',
      'What is bleaching, and what causes it?',
      'Can reefs recover?',
    ],
  ),
  PracticeTopic(
    id: 'stoicism',
    title: 'What Stoicism teaches about everyday problems',
    prompt:
        'Find out who the Stoics were, and which of their ideas people still '
        'use today.',
    categories: ['🤔 Philosophy'],
    emoji: '🏺',
    outline: [
      'Who were the Stoics?',
      'What did they believe we can control?',
      'Why are they popular again?',
    ],
  ),
  PracticeTopic(
    id: 'jazz',
    title: 'How jazz was born in New Orleans',
    prompt:
        'Find out which musical traditions met in New Orleans, and how jazz '
        'spread around the world.',
    categories: ['🎨 Arts & culture', '🏛️ History'],
    emoji: '🎷',
    outline: [
      'Why New Orleans?',
      'Which traditions shaped jazz?',
      'How did it travel the world?',
    ],
  ),
  PracticeTopic(
    id: 'renewables-grid',
    title: 'Why storing solar and wind power is so hard',
    prompt:
        'Find out why the grid needs balance, and which kinds of storage are '
        'being tried.',
    categories: ['🌍 Environment', '💻 Technology'],
    emoji: '🔋',
    outline: [
      'Why is solar and wind power irregular?',
      'Why must the grid stay balanced?',
      'How can energy be stored?',
    ],
  ),
  PracticeTopic(
    id: 'african-union',
    title: 'What the African Union does',
    prompt:
        'Find out why it replaced the OAU, how it is organised, and what the '
        'free trade area aims to do.',
    categories: ['🌐 Geopolitics', '🌱 Africa'],
    emoji: '🤝',
    outline: [
      'Where does the African Union come from?',
      'How is it organised?',
      'What is the African free trade area?',
    ],
  ),
  PracticeTopic(
    id: 'antibiotic-resistance',
    title: 'Why antibiotics are losing their power',
    prompt:
        'Find out how bacteria become resistant, and what is being done about '
        'it.',
    categories: ['🔬 Science', '🩺 Health'],
    emoji: '🦠',
    outline: [
      'How do antibiotics work?',
      'How do bacteria become resistant?',
      'What can be done?',
    ],
  ),
  PracticeTopic(
    id: 'large-language-models',
    title: 'How large language models write text',
    prompt:
        'Find out what a language model is trained on, and how it chooses the '
        'next word.',
    categories: ['💻 Technology'],
    emoji: '🤖',
    outline: [
      'What is a language model?',
      'How is it trained?',
      'Why does it sometimes make things up?',
    ],
  ),
  PracticeTopic(
    id: 'silk-road',
    title: 'What travelled along the Silk Road',
    prompt:
        'Find out which goods, ideas and diseases moved between China and the '
        'Mediterranean.',
    categories: ['🏛️ History', '💰 Economy'],
    emoji: '🐫',
    outline: [
      'What was the Silk Road?',
      'Which goods were traded?',
      'Which ideas travelled with them?',
    ],
  ),
  PracticeTopic(
    id: 'nollywood',
    title: 'How Nollywood became one of the biggest film industries',
    prompt:
        "Find out how Nigeria's film industry started, how it works, and why "
        'it reaches so many viewers.',
    categories: ['🎨 Arts & culture', '🌱 Africa'],
    emoji: '🎬',
    outline: [
      'How did Nollywood start?',
      'How are its films made and sold?',
      'Why is it so popular?',
    ],
  ),
  PracticeTopic(
    id: 'microplastics',
    title: 'Where microplastics come from and where they end up',
    prompt:
        'Find out what microplastics are, how they spread, and what is known '
        'about their effects.',
    categories: ['🌍 Environment', '🩺 Health'],
    emoji: '🧴',
    outline: [
      'What are microplastics?',
      'Where do they come from?',
      'Where do they end up?',
    ],
  ),
  PracticeTopic(
    id: 'remote-work',
    title: 'How remote work changed cities',
    prompt:
        'Find out what happened to offices, city centres and housing once '
        'many people stopped commuting.',
    categories: ['💰 Economy', '🌐 Geopolitics'],
    emoji: '🏙️',
    outline: [
      'How widespread is remote work?',
      'What happened to offices and city centres?',
      'Who gains and who loses?',
    ],
  ),
];

/// The topic with this [id], or a neutral stand-in if the catalog no longer
/// has it, so a session that drew it can still be shown.
PracticeTopic topicById(String id) {
  for (final topic in topicCatalog) {
    if (topic.id == id) return topic;
  }
  return PracticeTopic(
    id: id,
    title: 'A topic no longer in the list',
    prompt: '',
    categories: const [],
    emoji: '📝',
    outline: const [],
  );
}
