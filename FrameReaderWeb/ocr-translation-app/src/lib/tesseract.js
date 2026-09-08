import Tesseract from 'tesseract.js';

// Language configurations for different languages
export const LANGUAGE_CONFIGS = {
  urd: {
    code: 'urd',
    name: 'Urdu',
    script: 'Arabic',
    whitelist: 'آبپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی',
  },
  eng: {
    code: 'eng',
    name: 'English',
    script: 'Latin',
    whitelist: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
  },
  ara: {
    code: 'ara',
    name: 'Arabic',
    script: 'Arabic',
    whitelist: 'آأإابتثجحخدذرزسشصضطظعغفقكلمنهوي',
  },
  fas: {
    code: 'fas',
    name: 'Persian',
    script: 'Arabic',
    whitelist: 'آابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی',
  },
};

export const DEFAULT_LANGUAGES = ['urd', 'eng'];

export function getLanguageConfig(languageCode) {
  return LANGUAGE_CONFIGS[languageCode] || LANGUAGE_CONFIGS.eng;
}

export function getLanguageWhitelist(languages) {
  return languages
    .map(code => LANGUAGE_CONFIGS[code]?.whitelist || '')
    .join('');
}

export function getLanguageString(languages) {
  return languages.join('+');
}