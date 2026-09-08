import translate from 'google-translate-api-x';

// Language mapping for common languages
export const SUPPORTED_LANGUAGES = {
  'en': 'English',
  'ur': 'Urdu',
  'ar': 'Arabic',
  'fa': 'Persian',
  'fr': 'French',
  'es': 'Spanish',
  'de': 'German',
  'zh': 'Chinese',
  'hi': 'Hindi',
  'bn': 'Bengali',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'it': 'Italian',
  'nl': 'Dutch',
  'tr': 'Turkish',
  'vi': 'Vietnamese',
  'th': 'Thai',
  'id': 'Indonesian',
};

export async function translateText(text, targetLanguage = 'en', sourceLanguage = 'auto') {
  try {
    const result = await translate(text, {
      from: sourceLanguage,
      to: targetLanguage,
    });
    
    return {
      success: true,
      originalText: text,
      translatedText: result.text,
      sourceLanguage: result.from.language.iso,
      targetLanguage: targetLanguage,
    };
  } catch (error) {
    console.error('Translation error:', error);
    return {
      success: false,
      error: error.message,
    };
  }
}

export async function detectLanguage(text) {
  try {
    const result = await translate(text, { to: 'en' });
    return result.from.language.iso;
  } catch (error) {
    console.error('Language detection error:', error);
    return 'unknown';
  }
}

export async function getSupportedLanguages() {
  return SUPPORTED_LANGUAGES;
}

export function getLanguageName(code) {
  return SUPPORTED_LANGUAGES[code] || code;
}