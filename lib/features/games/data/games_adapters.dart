import '../engine/memory_engine.dart';
import '../engine/quiz_engine.dart';
import '../presentation/games_screens.dart';

/// The bundled trivia as the quiz engine's rows.
List<TriviaRow> triviaRows(List<TriviaQ> qs) => <TriviaRow>[
      for (final TriviaQ q in qs)
        (
          id: q.id,
          category: q.category,
          question: q.question,
          options: q.options,
          answer: q.answer,
          why: q.why,
        ),
    ];

/// The 99 Names as the memory game's rows.
List<MemoryName> memoryNames(List<Name99> names) => <MemoryName>[
      for (final Name99 n in names)
        (
          n: n.n,
          name: n.name,
          meaning: n.meaning,
          ref: n.ref,
          arabic: n.arabic,
        ),
    ];
