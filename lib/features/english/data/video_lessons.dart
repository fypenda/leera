import '../domain/session_feedback.dart';
import '../domain/video_lesson.dart';

/// The talks to watch, then retell, shortest first.
///
/// Each was checked against its transcript: the examples and the sentences
/// are the speaker's own words. To add one, check the YouTube id, and quote
/// only what is said in it.
const videoLessons = [
  VideoLesson(
    id: 'keep-your-goals-to-yourself',
    youtubeId: 'NHopJHSlVo4',
    title: 'Keep your goals to yourself',
    speaker: 'Derek Sivers',
    minutes: 3,
    level: 'B1',
    category: '🧠 Psychology',
    summary:
        'Derek Sivers argues that telling people about a goal makes you less '
        'likely to reach it. Psychology studies suggest that announcing a '
        'goal gives the mind the satisfaction of having done it, a false '
        'sense of progress. That good feeling reduces the effort you put into '
        'the real work. So keep your goals to yourself, or talk about them in '
        'a way that does not feel like an achievement.',
    listeningTip:
        'Short and fast: watch it twice. The first time, just follow the '
        'idea. The second time, listen for how he talks to the audience '
        'directly, with questions and "you".',
    expressions: [
      VocabularyItem(
        'keep your mouth shut',
        'To say nothing; to keep something secret (informal).',
        'Well, bad news: you should have kept your mouth shut, because that '
            'good feeling now will make you less likely to do it.',
      ),
      VocabularyItem(
        'one step closer',
        'Nearer to a goal, after some progress.',
        "Don't you feel one step closer already, like it's already becoming "
            'part of your identity?',
      ),
      VocabularyItem(
        'resist the temptation',
        'To stop yourself from doing something you want to do.',
        'Well, you could resist the temptation to announce your goal.',
      ),
      VocabularyItem(
        'hold someone to something',
        'To make someone do what they said they would do.',
        'So they hold us to it.',
      ),
      VocabularyItem(
        'take a second',
        'To take a very short time, to pause.',
        'For real — you can take a second.',
      ),
    ],
    phrasings: [
      (
        "The mind is kind of tricked into feeling that it's already done.",
        '"Kind of" softens the statement, as speakers often do; and "tricked '
            'into feeling" is a natural way to say "made to believe".',
      ),
      (
        "So audience, next time you're tempted to tell someone your goal, "
            'what will you say?',
        'A question to the listeners to end a talk: "next time you\'re '
            'tempted to…" is a common, friendly way to give advice.',
      ),
    ],
  ),
  VideoLesson(
    id: 'grit',
    youtubeId: 'H14bBuluwB8',
    title: 'Grit: the power of passion and perseverance',
    speaker: 'Angela Lee Duckworth',
    minutes: 6,
    level: 'B2',
    category: '🧠 Psychology',
    summary:
        'Angela Lee Duckworth left consulting to teach maths, and saw that '
        'IQ did not explain which students did well. Her research, at West '
        'Point, at the National Spelling Bee and in Chicago schools, found '
        'that grit, passion and perseverance for long-term goals, predicted '
        'success better than talent. Talent does not make you gritty. The '
        'best idea so far for building grit is the growth mindset, but she '
        'says science still knows little, and must test its ideas.',
    listeningTip:
        'She speaks clearly, at a steady pace: a good first TED talk. '
        'Listen for the words she stresses when she defines grit.',
    expressions: [
      VocabularyItem(
        'follow through on something',
        'To do what you planned or promised, until the end.',
        'Our data show very clearly that there are many talented individuals '
            'who simply do not follow through on their commitments.',
      ),
      VocabularyItem(
        'a marathon, not a sprint',
        'Something that needs long, steady effort rather than a short burst.',
        "Grit is living life like it's a marathon, not a sprint.",
      ),
      VocabularyItem(
        'in the long run',
        'Over a long period of time.',
        'How do I keep them motivated for the long run?',
      ),
      VocabularyItem(
        'the honest answer is',
        'A way to admit the truth, often that you do not know.',
        "The honest answer is, I don't know.",
      ),
      VocabularyItem(
        'in other words',
        'Used to say the same thing in a different, often simpler way.',
        'In other words, we need to be gritty about getting our kids '
            'grittier.',
      ),
    ],
    phrasings: [
      (
        "Some of my smartest kids weren't doing so well.",
        '"Weren\'t doing so well" is the natural, gentle way to say they had '
            'bad results.',
      ),
      (
        "What I do know is that talent doesn't make you gritty.",
        'The extra "do" stresses what she is sure of, after what she does '
            'not know.',
      ),
    ],
  ),
  VideoLesson(
    id: 'speak-so-people-listen',
    youtubeId: 'eIho2S0ZahI',
    title: 'How to speak so that people want to listen',
    speaker: 'Julian Treasure',
    minutes: 10,
    level: 'B2',
    category: '🗣️ Language',
    summary:
        'Julian Treasure, a sound expert, says the voice is powerful but '
        'often wasted. He names seven habits that make people hard to listen '
        'to, from gossip and judging to excuses and exaggeration. As a '
        'foundation he offers HAIL: honesty, authenticity, integrity and '
        'love. Then he shows the tools of the voice, such as register, '
        'timbre, prosody, pace, pitch and volume, and ends with exercises to '
        'warm up before you speak.',
    listeningTip:
        'He uses his own voice to show each tool. Listen to how his pace, '
        'pitch and volume change, not only to the words.',
    expressions: [
      VocabularyItem(
        'fall into a habit',
        'To start doing something regularly, without really deciding to.',
        "I'm not pretending this is an exhaustive list, but these seven, I "
            'think, are pretty large habits that we can all fall into.',
      ),
      VocabularyItem(
        'come into play',
        'To start to matter or have an effect.',
        "Of course, where this all comes into play most of all is when "
            "you've got something really important to do.",
      ),
      VocabularyItem(
        'go along with',
        'To happen together with something else.',
        'Of course, pitch often goes along with pace to indicate arousal, but '
            'you can do it just with pitch.',
      ),
      VocabularyItem(
        'warm up',
        'To prepare your body or voice with light exercise.',
        'Warm up your voice.',
      ),
      VocabularyItem(
        'in advance',
        'Before something happens.',
        'Next time you speak, do those in advance.',
      ),
    ],
    phrasings: [
      (
        "The human voice — it's the instrument we all play.",
        'Naming the subject first, then "it", is common in speech: it puts '
            'the idea at the front.',
      ),
      (
        'Give yourselves a round of applause.',
        'The usual way to ask an audience to clap.',
      ),
    ],
  ),
  VideoLesson(
    id: 'better-conversation',
    youtubeId: 'R1vskiVDwl4',
    title: '10 ways to have a better conversation',
    speaker: 'Celeste Headlee',
    minutes: 12,
    level: 'B2',
    category: '👥 Society',
    summary:
        'Celeste Headlee, a radio host, says that we talk more and listen '
        'less, and that phones and polarisation make it worse. She gives ten '
        'rules: be present, do not lecture, ask open-ended questions, go with the flow, say '
        'when you do not know, do not compare your experience with theirs, '
        'do not repeat yourself, stay out of the details, listen, and be '
        'brief. All of it comes down to one thing: be interested in other '
        'people.',
    listeningTip:
        'A radio voice: clear and well paced. Count the ten rules as she '
        'gives them, and note the one you find hardest.',
    expressions: [
      VocabularyItem(
        'boil down to',
        'To be, in the end, about one main thing.',
        'All of this boils down to the same basic concept, and it is this '
            'one: Be interested in other people.',
      ),
      VocabularyItem(
        'go with the flow',
        'To accept what happens, without trying to control it.',
        'Number four: Go with the flow.',
      ),
      VocabularyItem(
        'err on the side of caution',
        'To choose the safer option when you are not sure.',
        'Err on the side of caution.',
      ),
      VocabularyItem(
        'stay out of the weeds',
        'To avoid getting lost in too many small details.',
        'Number eight: Stay out of the weeds.',
      ),
      VocabularyItem(
        'take a cue from',
        'To follow the example of someone.',
        'In this case, take a cue from journalists.',
      ),
    ],
    phrasings: [
      (
        'Everybody is an expert in something.',
        'Short and simple: a natural way to make a point stick.',
      ),
      (
        'Conversations are not a promotional opportunity.',
        'A dry, slightly funny way of saying "don\'t talk only about '
            'yourself".',
      ),
    ],
  ),
  VideoLesson(
    id: 'good-life',
    youtubeId: '8KkKuTCFvzI',
    title: 'What makes a good life? Lessons from the longest study on '
        'happiness',
    speaker: 'Robert Waldinger',
    minutes: 13,
    level: 'B2',
    category: '🩺 Health',
    summary:
        'Robert Waldinger leads the Harvard Study of Adult Development, which '
        'has followed hundreds of men for 75 years. Its lesson is not about '
        'wealth, fame or working harder: good relationships keep us happier '
        'and healthier. Loneliness harms us, and so does living in conflict; '
        'what protects us is the quality of our close relationships. He '
        'suggests small steps, like spending time with people or repairing '
        'an old family quarrel.',
    listeningTip:
        'Calm and clear. Listen for the three lessons he announces, and the '
        'words he uses to join them.',
    expressions: [
      VocabularyItem(
        'it turns out that',
        'Used to say what was found, often a surprise.',
        'It turns out that people who are more socially connected to family, '
            'to friends, to community…',
      ),
      VocabularyItem(
        'when the going gets tough',
        'When a situation becomes difficult.',
        '…as long as they felt that they could really count on the other '
            'when the going got tough.',
      ),
      VocabularyItem(
        'day in and day out',
        'Every day, for a long time.',
        'Some of our octogenarian couples could bicker with each other day in '
            'and day out…',
      ),
      VocabularyItem(
        'fall apart',
        'To fail, or break into pieces.',
        'Almost all projects of this kind fall apart within a decade…',
      ),
      VocabularyItem(
        'in their wildest dreams',
        'Even in what they could imagine at most.',
        '…would never in their wildest dreams have imagined that I would be '
            'standing here today…',
      ),
    ],
    phrasings: [
      (
        'Good relationships keep us happier and healthier.',
        '"Keep us" + adjective is a natural pattern: it keeps me busy, it '
            'keeps us warm.',
      ),
      (
        'The good life is built with good relationships.',
        'Repeating "good" makes the conclusion easy to remember.',
      ),
    ],
  ),
  VideoLesson(
    id: 'master-procrastinator',
    youtubeId: 'arj7oStGLkU',
    title: 'Inside the mind of a master procrastinator',
    speaker: 'Tim Urban',
    minutes: 14,
    level: 'B2',
    category: '🧠 Psychology',
    summary:
        'Tim Urban describes the mind of a procrastinator as a Rational '
        'Decision-Maker sharing the wheel with an Instant Gratification '
        'Monkey, who wants what is easy and fun now. Near a deadline the '
        'Panic Monster wakes up and scares the Monkey away, so the work gets '
        'done at the last minute. The worse kind of procrastination has no '
        'deadline, and it can quietly hold back health, relationships or '
        'dreams for years. Everyone procrastinates on something, so we should '
        'notice what, while there is still time.',
    listeningTip:
        'Funny and fast. Turn on English subtitles the first time: the jokes '
        'go by quickly. Listen for the three characters.',
    expressions: [
      VocabularyItem(
        'take the wheel',
        'To take control of something.',
        'And finally, finally, the Rational Decision-Maker can take the wheel '
            'and I can start working on the talk.',
      ),
      VocabularyItem(
        'it turns out',
        'Used to say what was found, often a surprise.',
        "Well, it turns out that there's two kinds of procrastination.",
      ),
      VocabularyItem(
        'come and go',
        'To arrive and pass, here about time going by.',
        "Those first few months? They came and went, and I couldn't quite do "
            'stuff.',
      ),
      VocabularyItem(
        'no big deal',
        'Not important; not a problem.',
        'No big deal, right?',
      ),
      VocabularyItem(
        'have something on your mind',
        'To be thinking or worrying about something.',
        'But in the middle of all this excitement, the Rational '
            'Decision-Maker seemed to have something else on his mind.',
      ),
    ],
    phrasings: [
      (
        "It's not pretty, but in the end, it works.",
        '"It\'s not pretty" is a casual way to say something is messy.',
      ),
      (
        'Well, maybe not today, but … sometime soon.',
        'Starting with "well" and trailing off is how people speak, not how '
            'they write.',
      ),
    ],
  ),
  VideoLesson(
    id: 'stress-your-friend',
    youtubeId: 'RcGyVTAoXEU',
    title: 'How to make stress your friend',
    speaker: 'Kelly McGonigal',
    minutes: 14,
    level: 'B2',
    category: '🩺 Health',
    summary:
        'Kelly McGonigal, a health psychologist, admits she taught for years '
        'that stress makes you ill. A study changed her mind: stress harmed '
        'people mostly when they believed it was bad for them. Seeing your '
        'racing heart as your body getting ready helps your body respond in '
        'a healthier way. Stress also releases oxytocin, which pushes you to '
        'reach out to others, and caring for others builds resilience.',
    listeningTip:
        'Listen for the study she describes and its numbers. She asks the '
        'audience questions: try to answer them yourself.',
    expressions: [
      VocabularyItem(
        'freak someone out',
        'To scare or upset someone a lot (informal).',
        'You can see why this study freaked me out.',
      ),
      VocabularyItem(
        'do more harm than good',
        'To cause more problems than it solves.',
        "I fear that something I've been teaching for the last 10 years is "
            "doing more harm than good, and it has to do with stress.",
      ),
      VocabularyItem(
        'bottle something up',
        'To keep a feeling inside instead of showing it.',
        'Your biological stress response is nudging you to tell someone how '
            'you feel, instead of bottling it up.',
      ),
      VocabularyItem(
        'break out into a sweat',
        'To suddenly start sweating.',
        'Your heart might be pounding, you might be breathing faster, maybe '
            'breaking out into a sweat.',
      ),
      VocabularyItem(
        'get rid of',
        'To remove something you do not want.',
        'I no longer want to get rid of your stress.',
      ),
    ],
    phrasings: [
      (
        'Okay, so you get the idea.',
        'A natural way to stop listing examples: the audience has '
            'understood.',
      ),
      (
        'Chasing meaning is better for your health than trying to avoid '
            'discomfort.',
        'Two "-ing" subjects compared: a neat way to sum up an idea.',
      ),
    ],
  ),
  VideoLesson(
    id: 'great-leaders',
    youtubeId: 'qp0HIF3SfI4',
    title: 'How great leaders inspire action',
    speaker: 'Simon Sinek',
    minutes: 18,
    level: 'C1',
    category: '💼 Business',
    summary:
        'Simon Sinek says that inspiring leaders and companies start with '
        'why: their purpose and belief, before how and what. He calls it the '
        'Golden Circle, and links it to the part of the brain that makes '
        'decisions with feelings. People follow a cause they believe in, '
        'which is why the Wright brothers and Martin Luther King Jr. drew '
        'followers that richer rivals did not. People do not buy what you '
        'do; they buy why you do it.',
    listeningTip:
        'He draws a circle on a flipchart: imagine it as you listen. Listen '
        'for "why", "how" and "what", and the order he puts them in.',
    expressions: [
      VocabularyItem(
        'figure out',
        'To understand or solve something by thinking.',
        'Samuel Pierpont Langley was given 50,000 dollars by the War '
            'Department to figure out this flying machine.',
      ),
      VocabularyItem(
        'hate to break it to you',
        'Said before giving bad or surprising news.',
        "I hate to break it to you, those aren't other body parts "
            'controlling your behavior.',
      ),
      VocabularyItem(
        'lo and behold',
        'Used to introduce something surprising (a little humorous).',
        'And lo and behold, look what happened.',
      ),
      VocabularyItem(
        'year after year',
        'Every year, for many years.',
        "Year after year, after year, after year, they're more innovative "
            'than all their competition.',
      ),
      VocabularyItem(
        'in pursuit of',
        'Trying to get or achieve something.',
        'He was in pursuit of the riches.',
      ),
    ],
    phrasings: [
      (
        "People don't buy what you do; people buy why you do it.",
        'Repeating the structure makes the idea easy to remember: a classic '
            'device of speeches.',
      ),
      (
        'We follow those who lead, not for them, but for ourselves.',
        '"Not for… but for…" sets two ideas side by side for contrast.',
      ),
    ],
  ),
  VideoLesson(
    id: 'single-story',
    youtubeId: 'D9Ihs241zeg',
    title: 'The danger of a single story',
    speaker: 'Chimamanda Ngozi Adichie',
    minutes: 19,
    level: 'B2',
    category: '🌱 Africa',
    summary:
        'The Nigerian novelist Chimamanda Ngozi Adichie tells how the British '
        'and American books she read as a child shaped what she thought a '
        'story should be. She shows how a single story, of Africa or of any '
        'people, creates stereotypes and robs people of their dignity. Power '
        'decides whose stories are told, and how often. Many stories, she '
        'says, can repair what a single story breaks.',
    listeningTip:
        'A storyteller: follow her personal stories, each makes the same '
        'point. Notice her Nigerian English, clear and unhurried.',
    expressions: [
      VocabularyItem(
        'grow up',
        'To spend your childhood somewhere; to become an adult.',
        'I grew up on a university campus in eastern Nigeria.',
      ),
      VocabularyItem(
        'come up',
        'To be mentioned in a conversation.',
        'But in the U.S. whenever Africa came up people turned to me.',
      ),
      VocabularyItem(
        'buy into',
        'To believe an idea, often one that is not true.',
        'I had bought into the single story of Mexicans and I could not have '
            'been more ashamed of myself.',
      ),
      VocabularyItem(
        'never mind',
        'Used to say that something does not matter, or is not even '
            'considered.',
        'Never mind that I knew nothing about places like Namibia.',
      ),
      VocabularyItem(
        'in a fit of',
        'Suddenly feeling a strong emotion, and acting on it.',
        'Now, obviously I said this in a fit of mild irritation.',
      ),
    ],
    phrasings: [
      (
        'They make one story become the only story.',
        '"Make" + someone/something + verb: a natural pattern (it made me '
            'laugh).',
      ),
      (
        'Stories can break the dignity of a people, but stories can also '
            'repair that broken dignity.',
        'Repeating "stories" and "dignity" gives the sentence its weight.',
      ),
    ],
  ),
  VideoLesson(
    id: 'schools-creativity',
    youtubeId: 'iG9CE55wbtY',
    title: 'Do schools kill creativity?',
    speaker: 'Sir Ken Robinson',
    minutes: 20,
    level: 'C1',
    category: '👥 Society',
    summary:
        'Sir Ken Robinson argues that creativity matters as much as literacy '
        'in education. Schools rank subjects by how useful they seem for '
        'work, with the arts at the bottom, and they reward a narrow kind of '
        'intelligence. Children are not afraid of being wrong, but school '
        'teaches them to be, and so they lose their creativity as they grow. '
        'Education should be rethought to grow the whole person.',
    listeningTip:
        'Very funny, with a British accent and dry humour. Laugh with the '
        'audience: the jokes carry the argument.',
    expressions: [
      VocabularyItem(
        'be blown away',
        'To be very impressed or surprised.',
        "I've been blown away by the whole thing.",
      ),
      VocabularyItem(
        'have a go',
        'To try something (British).',
        "If they don't know, they'll have a go.",
      ),
      VocabularyItem(
        'grow out of',
        'To stop doing something as you get older.',
        "I believe this passionately, that we don't grow into creativity, we "
            'grow out of it.',
      ),
      VocabularyItem(
        'take a chance',
        'To try something although it may not work.',
        'What these things have in common is that kids will take a chance.',
      ),
      VocabularyItem(
        'to be honest',
        'Used before saying what you really think.',
        'When my son was four in England -- actually, he was four everywhere, '
            'to be honest.',
      ),
    ],
    phrasings: [
      (
        'The problem is to remain an artist as we grow up.',
        '"The problem is to…" introduces the real difficulty, in a simple '
            'way.',
      ),
      (
        'And the result is that we are educating people out of their '
            'creative capacities.',
        '"Educating people out of" plays on phrasal verbs: a creative use '
            'English allows.',
      ),
    ],
  ),
];

/// A lesson by its id, if it is in the list.
VideoLesson? videoLessonById(String id) {
  for (final lesson in videoLessons) {
    if (lesson.id == id) return lesson;
  }
  return null;
}

/// The lesson a session's topic retells, if it is one.
VideoLesson? videoLessonOfTopic(String topicId) {
  for (final lesson in videoLessons) {
    if (VideoLesson.topicIdOf(lesson.id) == topicId) return lesson;
  }
  return null;
}
