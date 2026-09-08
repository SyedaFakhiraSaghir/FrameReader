import { translateText, detectLanguage } from '@/lib/translations';

export async function translateWord(word, targetLanguage = 'en') {
  try {
    const result = await translateText(word, targetLanguage);
    return result;
  } catch (error) {
    console.error('Word translation error:', error);
    throw error;
  }
}

export async function translateBatch(words, targetLanguage = 'en') {
  try {
    const translations = await Promise.all(
      words.map(async (word) => {
        const result = await translateText(word, targetLanguage);
        return {
          original: word,
          translated: result.translatedText,
          confidence: result.confidence || 0.8,
        };
      })
    );
    return translations;
  } catch (error) {
    console.error('Batch translation error:', error);
    throw error;
  }
}

export function getLanguageOptions() {
  return [
    { value: 'en', label: 'English' },
    { value: 'ur', label: 'Urdu' },
    { value: 'ar', label: 'Arabic' },
    { value: 'fa', label: 'Persian' },
    { value: 'fr', label: 'French' },
    { value: 'es', label: 'Spanish' },
    { value: 'de', label: 'German' },
    { value: 'zh', label: 'Chinese' },
    { value: 'hi', label: 'Hindi' },
    { value: 'bn', label: 'Bengali' },
    { value: 'pt', label: 'Portuguese' },
    { value: 'ru', label: 'Russian' },
    { value: 'ja', label: 'Japanese' },
    { value: 'ko', label: 'Korean' },
  ];
}