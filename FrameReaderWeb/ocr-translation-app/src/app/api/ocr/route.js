import { NextResponse } from 'next/server';

// Simple OCR using a free API
export async function POST(request) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 }
      );
    }

    // Convert file to base64
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);
    const base64Image = buffer.toString('base64');

    // Use OCR.space free API (no API key required for limited usage)
    const response = await fetch('https://api.ocr.space/parse/image', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        base64Image: `data:${file.type};base64,${base64Image}`,
        language: 'eng',
        isOverlayRequired: 'false',
        detectOrientation: 'true',
        scale: 'true',
        isTable: 'false',
        OCREngine: '2', // Use both OCR engines for better accuracy
      }),
    });

    const data = await response.json();

    if (data.ErrorMessage) {
      throw new Error(data.ErrorMessage);
    }

    // Extract text from response
    const parsedResults = data.ParsedResults || [];
    const text = parsedResults.map(result => result.ParsedText).join('\n');

    // Extract words
    const words = text
      .trim()
      .split(/\s+/)
      .filter(word => word.length > 0);

    return NextResponse.json({
      text: text.trim(),
      confidence: parsedResults[0]?.TextOverlay?.Lines?.[0]?.Words?.[0]?.WordText || 0,
      words: words,
      wordCount: words.length,
      language: 'eng',
    });

  } catch (error) {
    console.error('OCR Error:', error);
    return NextResponse.json(
      { error: 'Failed to process OCR: ' + (error.message || 'Unknown error') },
      { status: 500 }
    );
  }
}