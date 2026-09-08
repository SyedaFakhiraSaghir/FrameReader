import { NextResponse } from 'next/server';
import Tesseract from 'tesseract.js';
import sharp from 'sharp';

export async function POST(request) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');
    const fileType = formData.get('type');

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 }
      );
    }

    // Convert file to buffer
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);
    
    // Process based on file type
    let processedBuffer = buffer;
    
    if (fileType?.startsWith('image/')) {
      try {
        // Optimize image for OCR
        processedBuffer = await sharp(buffer)
          .resize(1200, null, { withoutEnlargement: true })
          .grayscale()
          .sharpen()
          .toBuffer();
      } catch (sharpError) {
        console.warn('Sharp processing failed, using original:', sharpError);
        // Fall back to original buffer
        processedBuffer = buffer;
      }
    }

    // Perform OCR with better error handling
    let result;
    try {
      result = await Tesseract.recognize(processedBuffer, 'urd+eng', {
        logger: m => {
          if (m.status === 'recognizing text') {
            console.log(`OCR Progress: ${Math.round(m.progress * 100)}%`);
          }
        },
      });
    } catch (ocrError) {
      console.error('Tesseract OCR Error:', ocrError);
      return NextResponse.json(
        { error: 'OCR processing failed. Please try with a clearer image.' },
        { status: 500 }
      );
    }

    const text = result.data.text || '';
    
    // Extract words with better filtering
    const words = text
      .trim()
      .split(/\s+/)
      .filter(word => word.length > 0);

    return NextResponse.json({
      text: text.trim(),
      confidence: result.data.confidence || 0,
      words: words,
      wordCount: words.length,
      language: 'urd+eng',
    });

  } catch (error) {
    console.error('OCR Error:', error);
    return NextResponse.json(
      { error: 'Failed to process OCR: ' + (error.message || 'Unknown error') },
      { status: 500 }
    );
  }
}