<?php

namespace App\Services;

class ProfanityFilter
{
    /**
     * List of inappropriate words (Indonesian + English)
     * Each word is stored in lowercase for case-insensitive matching
     */
    private static array $blacklist = [
        // Indonesian profanity
        'anjing', 'bangsat', 'bajingan', 'kontol', 'memek', 'pepek', 'tempek',
        'kampret', 'goblok', 'goblog', 'bego', 'tolol', 'idiot', 'bodoh',
        'bngst', 'anj', 'kntl', 'mmk', 'ppk', 'tmpk', 'kpr', 'jancuk',
        'tai', 'tahi', 'pet', 'peler', 'pelir', 'bego', 'dongo', 'norak',
        'sialan', 'setan', 'iblis', 'bitch', 'fuck', 'shit', 'damn', 'hell',
        'ass', 'asshole', 'bastard', 'dick', 'pussy', 'cock', 'crap',
        'slut', 'whore', 'damn', 'retard', 'stfu', 'wtf', 'lgbt',
        'pantek', 'pantat', 'burit', 'vagina', 'penis', 'kimak', 'cibai',
        'cina', 'chinca', 'pki', 'komunis', 'kaum', 'bangke',
        // Common variations & leetspeak
        '4nj1ng', 'b4ng5at', 'k0nt0l', 'g0bl0k', 't0l0l',
        'anj1ng', 'banci', 'bencong', 'waria', 'homo', 'gay',
        'lonte', 'psk', 'muncrat', 'colme', 'coli', 'ngocok',
    ];

    /**
     * Get words to censor, sorted by length (longest first) to prevent partial matches
     */
    private static function getWordsToCensor(): array
    {
        $words = self::$blacklist;
        usort($words, fn($a, $b) => strlen($b) - strlen($a));
        return $words;
    }

    /**
     * Censor inappropriate words in a string
     * Replaces each character of the matched word with *
     *
     * @param string $text The text to filter
     * @return string The filtered text with censored words
     */
    public static function censor(string $text): string
    {
        if (empty($text)) {
            return $text;
        }

        $words = self::getWordsToCensor();
        $result = $text;

        foreach ($words as $word) {
            if (strlen($word) < 2) continue;

            // Case-insensitive match with word boundaries
            $pattern = '/\b' . preg_quote($word, '/') . '\b/i';

            $result = preg_replace_callback($pattern, function ($matches) {
                return str_repeat('*', strlen($matches[0]));
            }, $result);
        }

        return $result;
    }

    /**
     * Check if text contains inappropriate words
     *
     * @param string $text The text to check
     * @return bool True if inappropriate words are found
     */
    public static function containsProfanity(string $text): bool
    {
        if (empty($text)) {
            return false;
        }

        $lower = strtolower($text);
        $words = self::getWordsToCensor();

        foreach ($words as $word) {
            if (strlen($word) < 2) continue;
            $pattern = '/\b' . preg_quote($word, '/') . '\b/i';
            if (preg_match($pattern, $lower)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get list of detected inappropriate words (for admin logging)
     *
     * @param string $text The text to check
     * @return array List of detected words
     */
    public static function getDetectedWords(string $text): array
    {
        if (empty($text)) {
            return [];
        }

        $detected = [];
        $words = self::getWordsToCensor();

        foreach ($words as $word) {
            if (strlen($word) < 2) continue;
            $pattern = '/\b' . preg_quote($word, '/') . '\b/i';
            if (preg_match($pattern, $text)) {
                $detected[] = $word;
            }
        }

        return $detected;
    }
}
