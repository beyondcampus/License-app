const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
// The snapshot of the Supabase content written by tools/export_supabase_assets.js.
const dataDir = path.join(root, 'test', 'fixtures', 'content');

const readJson = (file) => JSON.parse(fs.readFileSync(path.join(dataDir, file), 'utf8'));

const chapters = readJson('chapters.json');
const topics = readJson('topics.json');
const theory = readJson('theory.json');
const questions = readJson('questions.json');
const formulas = readJson('formulas.json');
const flashcards = readJson('flashcards.json');

const ids = (items) => items.map((item) => item.id).filter(Boolean);
const duplicates = (values) => {
  const seen = new Set();
  const duplicate = new Set();
  for (const value of values) {
    if (seen.has(value)) duplicate.add(value);
    seen.add(value);
  }
  return [...duplicate];
};

const problems = [];
const chapterIds = new Set(chapters.map((chapter) => chapter.id));
const topicIds = new Set(topics.map((topic) => topic.id));

for (const [name, items] of Object.entries({ chapters, topics, questions, formulas, flashcards })) {
  const duplicateIds = duplicates(ids(items));
  if (duplicateIds.length) {
    problems.push(`${name} has duplicate IDs: ${duplicateIds.slice(0, 10).join(', ')}`);
  }
}

for (const topic of topics) {
  if (!chapterIds.has(topic.chapterId)) {
    problems.push(`topic ${topic.id} references missing chapter ${topic.chapterId}`);
  }
}

for (const question of questions) {
  if (!chapterIds.has(question.chapterId)) {
    problems.push(`question ${question.id} references missing chapter ${question.chapterId}`);
  }
  if (!topicIds.has(question.topicId)) {
    problems.push(`question ${question.id} references missing topic ${question.topicId}`);
  }
  if (!Array.isArray(question.options) || question.options.length < 2) {
    problems.push(`question ${question.id} has fewer than two options`);
  }
  if (!Number.isInteger(question.correctIndex) || question.correctIndex < 0 || question.correctIndex >= question.options.length) {
    problems.push(`question ${question.id} has invalid correctIndex`);
  }
}

for (const formula of formulas) {
  if (!chapterIds.has(formula.chapterId)) {
    problems.push(`formula ${formula.id} references missing chapter ${formula.chapterId}`);
  }
  if (!topicIds.has(formula.topicId)) {
    problems.push(`formula ${formula.id} references missing topic ${formula.topicId}`);
  }
}

for (const flashcard of flashcards) {
  if (!chapterIds.has(flashcard.chapterId)) {
    problems.push(`flashcard ${flashcard.id} references missing chapter ${flashcard.chapterId}`);
  }
  if (!topicIds.has(flashcard.topicId)) {
    problems.push(`flashcard ${flashcard.id} references missing topic ${flashcard.topicId}`);
  }
}

for (const content of theory) {
  if (!topicIds.has(content.topicId)) {
    problems.push(`theory content references missing topic ${content.topicId}`);
  }
}

const counts = {
  chapters: chapters.length,
  topics: topics.length,
  theory: theory.length,
  questions: questions.length,
  formulas: formulas.length,
  flashcards: flashcards.length,
};

console.log(JSON.stringify({ counts, problems }, null, 2));

if (problems.length) {
  process.exit(1);
}
