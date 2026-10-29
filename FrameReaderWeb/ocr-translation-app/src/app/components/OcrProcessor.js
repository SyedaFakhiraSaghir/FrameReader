'use client';

import { useState } from 'react';
import Tesseract from 'tesseract.js';

export default function OcrProcessor({ imageFile, onComplete }) {
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState(0);

  const processImage = async () => {
    if (!imageFile) return;

    setProcessing(true);
    setProgress(0);

    try {
      const result = await Tesseract.recognize(imageFile, 'urd+eng', {
        logger: (m) => {
          if (m.status === 'recognizing text') {
            setProgress(Math.round(m.progress * 100));
          }
        },
      });

      const text = result.data.text || '';
      const words = text
        .trim()
        .split(/\s+/)
        .filter(word => word.length > 0);

      onComplete({
        text: text.trim(),
        words: words,
        wordCount: words.length,
      });
    } catch (error) {
      console.error('OCR Error:', error);
      alert('Failed to process OCR. Please try again.');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="space-y-4">
      <button
        onClick={processImage}
        disabled={processing}
        className="btn-primary disabled:opacity-50"
      >
        {processing ? 'Processing...' : 'Extract Text'}
      </button>
      
      {processing && (
        <div className="space-y-2">
          <div className="w-full bg-gray-200 rounded-full h-2.5">
            <div
              className="bg-primary h-2.5 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
          <p className="text-sm text-gray-600">{progress}% complete</p>
        </div>
      )}
    </div>
  );
}