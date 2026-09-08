import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const body = await request.json();
    const { text, targetLanguage = 'en' } = body;

    if (!text) {
      return NextResponse.json(
        { error: 'No text provided' },
        { status: 400 }
      );
    }

    // Simple translation using fetch (no external dependencies)
    const response = await fetch(
      `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=auto|${targetLanguage}`
    );

    if (!response.ok) {
      throw new Error('Translation service failed');
    }

    const data = await response.json();

    return NextResponse.json({
      originalText: text,
      translatedText: data.responseData?.translatedText || text,
      sourceLanguage: 'auto',
      targetLanguage: targetLanguage,
    });

  } catch (error) {
    console.error('Translation Error:', error);
    // Return a fallback translation
    return NextResponse.json({
      originalText: text,
      translatedText: text,
      sourceLanguage: 'auto',
      targetLanguage: targetLanguage,
      error: 'Translation service temporarily unavailable',
    });
  }
}