const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const dataDir = path.join(root, 'test', 'fixtures', 'content');
const sourceDir = path.join(__dirname, 'chapter_sources');

const chapterNumberFromFile = (file) => {
  const match = path.basename(file).match(/^chap(\d+)\.json$/i);
  return match ? Number(match[1]) : Number.POSITIVE_INFINITY;
};

if (!fs.existsSync(sourceDir)) {
  console.error(`Chapter source directory not found: ${sourceDir}`);
  process.exit(1);
}

const chapterFiles = fs
  .readdirSync(sourceDir)
  .filter((name) => /^chap\d+\.json$/i.test(name))
  .map((name) => path.join(sourceDir, name))
  .sort((a, b) => chapterNumberFromFile(a) - chapterNumberFromFile(b));

if (chapterFiles.length === 0) {
  console.error(`No chap*.json files found in ${sourceDir}`);
  process.exit(1);
}

const readJson = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const writeJson = (file, value) => {
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
};

const validateChapterSource = (chapter, file) => {
  const label = path.relative(root, file);
  const problems = [];
  if (!Number.isInteger(Number(chapter.chapter_number))) {
    problems.push('chapter_number must be present');
  }
  if (!chapter.chapter_title) {
    problems.push('chapter_title must be present');
  }
  if (!Array.isArray(chapter.subsections)) {
    problems.push('subsections must be an array');
  }
  if (!Array.isArray(chapter.questions)) {
    problems.push('questions must be an array');
  }

  for (const [subsectionIndex, subsection] of (chapter.subsections || []).entries()) {
    if (!subsection.id) problems.push(`subsections[${subsectionIndex}].id is missing`);
    if (!subsection.title) problems.push(`subsections[${subsectionIndex}].title is missing`);
    if (!Array.isArray(subsection.topics)) {
      problems.push(`subsections[${subsectionIndex}].topics must be an array`);
      continue;
    }
    for (const [topicIndex, topic] of subsection.topics.entries()) {
      if (!topic.title) problems.push(`subsections[${subsectionIndex}].topics[${topicIndex}].title is missing`);
      if (!topic.content) problems.push(`subsections[${subsectionIndex}].topics[${topicIndex}].content is missing`);
    }
  }

  for (const [questionIndex, question] of (chapter.questions || []).entries()) {
    if (!question.question) problems.push(`questions[${questionIndex}].question is missing`);
    if (!Array.isArray(question.options) || question.options.length < 2) {
      problems.push(`questions[${questionIndex}].options must contain at least two options`);
    }
    if (!Number.isInteger(question.correct_answer_index)) {
      problems.push(`questions[${questionIndex}].correct_answer_index must be an integer`);
    } else if (Array.isArray(question.options) && (question.correct_answer_index < 0 || question.correct_answer_index >= question.options.length)) {
      problems.push(`questions[${questionIndex}].correct_answer_index is out of range`);
    }
  }

  if (problems.length) {
    throw new Error(`${label} is invalid:\n- ${problems.join('\n- ')}`);
  }
};

const normalize = (value) =>
  String(value || '')
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9+]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const stopWords = new Set([
  'and',
  'or',
  'the',
  'of',
  'in',
  'with',
  'a',
  'an',
  'to',
  'its',
  'basic',
  'basics',
  'fundamentals',
  'system',
  'systems',
  'circuits',
  'circuit',
]);

const tokens = (value) =>
  normalize(value)
    .split(' ')
    .filter((token) => token.length > 1 && !stopWords.has(token));

const tokenScore = (left, right) => {
  const a = new Set(tokens(left));
  const b = new Set(tokens(right));
  if (!a.size || !b.size) return 0;
  let shared = 0;
  for (const token of a) {
    if (b.has(token)) shared += 1;
  }
  return shared / Math.min(a.size, b.size);
};

const titleCase = (value) =>
  String(value || '')
    .toLowerCase()
    .replace(/\b[a-z]/g, (letter) => letter.toUpperCase())
    .replace(/\bAnd\b/g, '&')
    .replace(/\bAc\b/g, 'AC')
    .replace(/\bDc\b/g, 'DC')
    .replace(/\bBjt\b/g, 'BJT')
    .replace(/\bMosfet\b/g, 'MOSFET')
    .replace(/\bCmos\b/g, 'CMOS')
    .replace(/\bCpu\b/g, 'CPU')
    .replace(/\bIo\b/g, 'I/O')
    .replace(/\bDma\b/g, 'DMA');

const difficultyFor = (index) => (index % 5 === 4 ? 'hard' : index % 3 === 1 ? 'medium' : 'easy');

const conceptBlocks = (topic) => {
  const blocks = [{ type: 'heading', text: topic.title }];
  const chunks = String(topic.content || '')
    .split(/\n\s*\n/g)
    .map((chunk) => chunk.trim())
    .filter(Boolean);

  for (const chunk of chunks) {
    const lines = chunk.split('\n').map((line) => line.trim()).filter(Boolean);
    const bulletItems = lines
      .filter((line) => /^[-*]\s+/.test(line))
      .map((line) => line.replace(/^[-*]\s+/, ''));
    if (bulletItems.length >= 2) {
      const lead = lines.find((line) => !/^[-*]\s+/.test(line)) || 'Key points:';
      blocks.push({ type: 'bulletList', text: lead, items: bulletItems });
    } else {
      blocks.push({ type: 'paragraph', text: chunk });
    }
  }

  return blocks;
};

const formulaCandidates = (content) =>
  String(content || '')
    .split('\n')
    .map((line) => line.trim().replace(/^[-*]\s+/, ''))
    .filter((line) => {
      const hasFormulaLabel = /formula|equation|relation|frequency|power|impedance|reactance|gain|efficiency/i.test(line);
      return hasFormulaLabel && /=|√|π|\^|²|³|Σ|∑|×|\/|\+|-/.test(line);
    })
    .slice(0, 5);

const makeSubtitle = (content, subsectionTitle) => {
  const firstLine = String(content || '').split('\n').find((line) => line.trim()) || subsectionTitle;
  return firstLine.replace(/^[-*]\s+/, '').slice(0, 95);
};

const existingChapters = readJson(path.join(dataDir, 'chapters.json'));
const existingTopics = readJson(path.join(dataDir, 'topics.json'));
const existingTheory = readJson(path.join(dataDir, 'theory.json'));
const existingQuestions = readJson(path.join(dataDir, 'questions.json'));
const existingFormulas = readJson(path.join(dataDir, 'formulas.json'));
const existingFlashcards = readJson(path.join(dataDir, 'flashcards.json'));
const incomingChapters = chapterFiles.map((file) => {
  try {
    const chapter = readJson(file);
    validateChapterSource(chapter, file);
    return chapter;
  } catch (error) {
    console.error(`Failed to read ${path.relative(root, file)}:`);
    console.error(error.message);
    process.exit(1);
  }
});

const chapters = [...existingChapters];
const topics = [...existingTopics];
const theory = [...existingTheory];
const questions = [...existingQuestions];
const formulas = [...existingFormulas];
const flashcards = [...existingFlashcards];

const theoryByTopic = new Map(theory.map((entry) => [entry.topicId, entry]));
const chapterById = new Map(chapters.map((chapter) => [chapter.id, chapter]));
const questionsByChapter = new Map();
for (const question of questions) {
  const key = question.chapterId;
  if (!questionsByChapter.has(key)) questionsByChapter.set(key, new Set());
  questionsByChapter.get(key).add(normalize(question.questionText));
}
const formulaKeys = new Set(formulas.map((formula) => `${formula.topicId}:${normalize(formula.plainText)}`));
const flashcardKeys = new Set(flashcards.map((card) => `${card.topicId}:${normalize(card.front)}`));
const usedFormulaIds = new Set(formulas.map((formula) => formula.id));
const usedFlashcardIds = new Set(flashcards.map((card) => card.id));

const slug = (value) =>
  normalize(value)
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 24);

const uniqueId = (base, used) => {
  let candidate = base;
  let suffix = 2;
  while (used.has(candidate)) {
    candidate = `${base}_${suffix}`;
    suffix += 1;
  }
  used.add(candidate);
  return candidate;
};

const chapterDescriptions = {
  ch1: 'Electrical fundamentals, network theorems, AC quantities, semiconductor devices, oscillators and amplifiers.',
  ch2: 'Digital logic, combinational and sequential circuits, microprocessors, memory, DMA and interrupts.',
  ch3: 'C programming, pointers, file handling, C++ OOP, templates, STL and exception handling.',
  ch4: 'Computer organization, architecture, memory hierarchy, instruction execution and embedded systems.',
  ch5: 'Computer networks, protocols, communication models, routing, switching and network security.',
  ch6: 'Theory of computation, formal languages, automata, computability and computer graphics.',
  ch7: 'Data structures, algorithms, database systems and operating-system concepts.',
  ch8: 'Software engineering, process models, testing, project management and object-oriented analysis and design.',
  ch9: 'Artificial intelligence, search, knowledge representation, machine learning and neural networks.',
};

const chapterEmoji = {
  ch1: '⚡',
  ch2: '💻',
  ch3: '👨‍💻',
  ch4: '🧠',
};

const topicTargetBySource = new Map();
const importSummary = [];

for (const chapter of incomingChapters) {
  const chapterId = `ch${chapter.chapter_number}`;
  if (!chapterById.has(chapterId)) {
    const newChapter = {
      id: chapterId,
      title: chapter.chapter_title,
      description: chapterDescriptions[chapterId] || chapter.chapter_title,
      emoji: chapterEmoji[chapterId] || '📘',
      order: Number(chapter.chapter_number),
    };
    chapters.push(newChapter);
    chapterById.set(chapterId, newChapter);
  }

  let addedTopics = 0;
  let mergedTopics = 0;
  let nextOrder =
    Math.max(0, ...topics.filter((topic) => topic.chapterId === chapterId).map((topic) => topic.order || 0)) + 1;

  chapter.subsections.forEach((subsection, subsectionIndex) => {
    subsection.topics.forEach((incomingTopic, topicIndex) => {
      const sourceKey = `${chapterId}:${subsection.id}:${topicIndex}`;
      const candidates = topics.filter((topic) => topic.chapterId === chapterId);
      let best = null;
      let bestScore = 0;
      for (const candidate of candidates) {
        const score = Math.max(
          tokenScore(incomingTopic.title, candidate.title),
          tokenScore(`${incomingTopic.title} ${incomingTopic.content}`, `${candidate.title} ${candidate.subtitle}`),
        );
        if (score > bestScore) {
          best = candidate;
          bestScore = score;
        }
      }

      let targetTopic = bestScore >= 0.55 ? best : null;
      if (targetTopic) {
        mergedTopics += 1;
      } else {
        targetTopic = {
          id: `${chapterId}_i${String(nextOrder).padStart(2, '0')}`,
          chapterId,
          title: titleCase(incomingTopic.title),
          subtitle: makeSubtitle(incomingTopic.content, subsection.title),
          order: nextOrder,
          hasFormulas: formulaCandidates(incomingTopic.content).length > 0,
          hasNotes: true,
        };
        nextOrder += 1;
        topics.push(targetTopic);
        addedTopics += 1;
      }
      topicTargetBySource.set(sourceKey, targetTopic.id);

      const targetTheory = theoryByTopic.get(targetTopic.id) || {
        topicId: targetTopic.id,
        concepts: [],
        formulas: [],
        notes: [],
      };
      if (!theoryByTopic.has(targetTopic.id)) {
        theory.push(targetTheory);
        theoryByTopic.set(targetTopic.id, targetTheory);
      }

      const alreadyImported = targetTheory.concepts.some(
        (block) => block.type === 'heading' && normalize(block.text) === normalize(incomingTopic.title),
      );
      if (!alreadyImported) {
        targetTheory.concepts.push(...conceptBlocks(incomingTopic));
        for (const candidate of formulaCandidates(incomingTopic.content)) {
          if (!targetTheory.formulas.some((block) => normalize(block.plainText || block.text) === normalize(candidate))) {
            targetTheory.formulas.push({ type: 'formula', plainText: candidate });
          }
        }
        targetTheory.notes.push({
          type: 'note',
          text: `Imported from ${subsection.id} ${titleCase(subsection.title)}.`,
        });
      }

      formulaCandidates(incomingTopic.content).forEach((plainText, formulaIndex) => {
        const key = `${targetTopic.id}:${normalize(plainText)}`;
        if (formulaKeys.has(key)) return;
        formulaKeys.add(key);
        formulas.push({
          id: uniqueId(
            `f_${targetTopic.id}_${slug(incomingTopic.title)}_${String(formulaIndex + 1).padStart(2, '0')}`,
            usedFormulaIds,
          ),
          chapterId,
          topicId: targetTopic.id,
          title: `${targetTopic.title} Reference ${formulaIndex + 1}`,
          plainText,
          description: `Formula/reference extracted from ${incomingTopic.title}.`,
        });
      });

      const front = `What should you remember about ${incomingTopic.title}?`;
      const cardKey = `${targetTopic.id}:${normalize(front)}`;
      if (!flashcardKeys.has(cardKey)) {
        flashcardKeys.add(cardKey);
        flashcards.push({
          id: uniqueId(`fc_${targetTopic.id}_${slug(incomingTopic.title)}`, usedFlashcardIds),
          chapterId,
          topicId: targetTopic.id,
          front,
          back: String(incomingTopic.content || '').split('\n').find((line) => line.trim()) || incomingTopic.title,
          difficulty: 'medium',
        });
      }
    });
  });

  let addedQuestions = 0;
  const seenQuestions = questionsByChapter.get(chapterId) || new Set();
  questionsByChapter.set(chapterId, seenQuestions);

  chapter.questions.forEach((incomingQuestion, index) => {
    const questionText = incomingQuestion.question;
    const normalizedQuestion = normalize(questionText);
    if (seenQuestions.has(normalizedQuestion)) return;

    let bestSourceKey = null;
    let bestScore = -1;
    chapter.subsections.forEach((subsection) => {
      subsection.topics.forEach((incomingTopic, topicIndex) => {
        const sourceKey = `${chapterId}:${subsection.id}:${topicIndex}`;
        const score = tokenScore(
          `${questionText} ${incomingQuestion.explanation}`,
          `${incomingTopic.title} ${incomingTopic.content}`,
        );
        if (score > bestScore) {
          bestScore = score;
          bestSourceKey = sourceKey;
        }
      });
    });

    const topicId = topicTargetBySource.get(bestSourceKey) || topics.find((topic) => topic.chapterId === chapterId)?.id;
    if (!topicId) return;
    seenQuestions.add(normalizedQuestion);
    addedQuestions += 1;
    questions.push({
      id: `q_${chapterId}_import_${String(index + 1).padStart(3, '0')}`,
      chapterId,
      topicId,
      questionText,
      options: incomingQuestion.options || [],
      correctIndex: Number(incomingQuestion.correct_answer_index),
      explanation: incomingQuestion.explanation || '',
      difficulty: difficultyFor(index),
    });
  });

  importSummary.push({ chapterId, addedTopics, mergedTopics, addedQuestions });
}

chapters.sort((a, b) => (a.order || 0) - (b.order || 0));
topics.sort((a, b) => (a.chapterId === b.chapterId ? (a.order || 0) - (b.order || 0) : a.chapterId.localeCompare(b.chapterId)));
questions.sort((a, b) => a.id.localeCompare(b.id));
formulas.sort((a, b) => a.id.localeCompare(b.id));
flashcards.sort((a, b) => a.id.localeCompare(b.id));

writeJson(path.join(dataDir, 'chapters.json'), chapters);
writeJson(path.join(dataDir, 'topics.json'), topics);
writeJson(path.join(dataDir, 'theory.json'), theory);
writeJson(path.join(dataDir, 'questions.json'), questions);
writeJson(path.join(dataDir, 'formulas.json'), formulas);
writeJson(path.join(dataDir, 'flashcards.json'), flashcards);

console.table(importSummary);
console.log(
  JSON.stringify(
    {
      chapters: chapters.length,
      topics: topics.length,
      theory: theory.length,
      questions: questions.length,
      formulas: formulas.length,
      flashcards: flashcards.length,
    },
    null,
    2,
  ),
);
