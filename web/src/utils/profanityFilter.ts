/**
 * Frontend profanity filter for censoring inappropriate words
 * Backend already applies this, but this provides an extra safety layer
 */

const blacklistedWords: string[] = [
  // Indonesian profanity
  'anjing', 'bangsat', 'bajingan', 'kontol', 'memek', 'pepek', 'tempek',
  'kampret', 'goblok', 'goblog', 'bego', 'tolol', 'idiot', 'bodoh',
  'bngst', 'anj', 'kntl', 'mmk', 'ppk', 'tmpk', 'kpr', 'jancuk',
  'tai', 'tahi', 'pet', 'peler', 'pelir', 'dongo', 'norak',
  'sialan', 'setan', 'iblis', 'bitch', 'fuck', 'shit', 'damn', 'hell',
  'ass', 'asshole', 'bastard', 'dick', 'pussy', 'cock', 'crap',
  'slut', 'whore', 'retard', 'stfu', 'wtf',
  'pantek', 'pantat', 'burit', 'vagina', 'penis', 'kimak', 'cibai',
  'bangke', 'banci', 'bencong', 'lonte', 'psk',
  // Common variations & leetspeak
  '4nj1ng', 'b4ng5at', 'k0nt0l', 'g0bl0k', 't0l0l', 'anj1ng',
];

// Sort by length (longest first) to prevent partial matches
const sortedWords = [...blacklistedWords].sort((a, b) => b.length - a.length);

/**
 * Censor inappropriate words in text
 * Replaces each character of matched words with *
 */
export function censorText(text: string): string {
  if (!text) return text;

  let result = text;

  for (const word of sortedWords) {
    if (word.length < 2) continue;

    // Build regex with word boundaries, case-insensitive
    const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`\\b${escaped}\\b`, 'gi');

    result = result.replace(regex, (match) => '*'.repeat(match.length));
  }

  return result;
}

/**
 * Check if text contains profanity
 */
export function hasProfanity(text: string): boolean {
  if (!text) return false;

  const lower = text.toLowerCase();

  for (const word of sortedWords) {
    if (word.length < 2) continue;
    const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`\\b${escaped}\\b`, 'i');
    if (regex.test(lower)) return true;
  }

  return false;
}
