import Tesseract from 'tesseract.js';
import { getLanguageString, getLanguageWhitelist } from '@/lib/tesseract';

export async function performOCR(imageBuffer, languages = ['urd', 'eng']) {
  try {
    const languageString = getLanguageString(languages);
    const whitelist = getLanguageWhitelist(languages);

    const result = await Tesseract.recognize(
      imageBuffer,
      languageString,
      {
        logger: m => console.log(m),
        tessedit_char_whitelist: whitelist,
      }
    );

    return {
      text: result.data.text.trim(),
      confidence: result.data.confidence,
      words: result.data.words,
      lines: result.data.lines,
    };
  } catch (error) {
    console.error('OCR Error:', error);
    throw error;
  }
}

export function extractWords(text) {
  return text
    .trim()
    .split(/\s+/)
    .filter(word => word.length > 0);
}

export function getTextBlocks(lines) {
  return lines.map(line => ({
    text: line.text,
    confidence: line.confidence,
    bbox: line.bbox,
    words: line.words,
  }));
}