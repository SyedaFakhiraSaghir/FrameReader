'use client';

import { useState } from 'react';

export default function OcrResult({ results, onWordClick }) {
  const [selectedWord, setSelectedWord] = useState(null);
  const [translation, setTranslation] = useState(null);
  const [isTranslating, setIsTranslating] = useState(false);

  const handleWordClick = async (word) => {
    if (!word || word.trim().length === 0) return;
    
    setSelectedWord(word);
    setIsTranslating(true);
    
    try {
      const response = await fetch('/api/translate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: word,
          targetLanguage: 'en',
        }),
      });

      const data = await response.json();
      setTranslation(data);
      if (onWordClick) onWordClick(word);
    } catch (error) {
      console.error('Translation Error:', error);
      // Set a fallback translation
      setTranslation({
        originalText: word,
        translatedText: 'Translation unavailable',
      });
    } finally {
      setIsTranslating(false);
    }
  };

  if (!results || !results.text) {
    return (
      <div className="card">
        <p className="text-gray-500 text-center">No text extracted yet. Upload a file to begin.</p>
      </div>
    );
  }

  const words = results.text.split(' ').filter(w => w.trim().length > 0);

  return (
    <div className="card">
      <h3 className="text-xl font-semibold text-gray-900 mb-4">
        Extracted Text
        {results.confidence && (
          <span className="ml-2 text-sm font-normal text-gray-500">
            (Confidence: {Math.round(results.confidence)}%)
          </span>
        )}
      </h3>
      
      <div className="space-y-4">
        <div className="bg-gray-50 rounded-lg p-4">
          <p className="text-sm text-gray-600 mb-2">
            Click on any word to see its meaning/translation
          </p>
          
          <div className="prose max-w-none">
            <div className="space-y-2">
              <p className="text-gray-800 leading-relaxed">
                {words.map((word, index) => (
                  <span
                    key={index}
                    onClick={() => handleWordClick(word)}
                    className="cursor-pointer hover:text-primary hover:underline transition-colors mx-0.5 inline-block"
                    style={{ padding: '2px 4px' }}
                  >
                    {word}
                  </span>
                ))}
              </p>
            </div>
          </div>
        </div>

        {selectedWord && (
          <div className="border-t border-gray-200 pt-4">
            <h4 className="font-medium text-gray-700">Word Translation</h4>
            <div className="mt-2 bg-indigo-50 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-lg font-semibold text-gray-900">
                    {selectedWord}
                  </p>
                  {translation && (
                    <p className="text-sm text-gray-600 mt-1">
                      Translation: {translation.translatedText || 'Unavailable'}
                    </p>
                  )}
                  {!translation && !isTranslating && (
                    <p className="text-sm text-gray-500 mt-1">
                      Click again to retry translation
                    </p>
                  )}
                </div>
                {isTranslating && (
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-primary"></div>
                )}
              </div>
            </div>
          </div>
        )}

        <div className="flex justify-end space-x-2">
          <button
            onClick={() => {
              setSelectedWord(null);
              setTranslation(null);
            }}
            className="text-sm text-gray-500 hover:text-gray-700"
          >
            Clear Selection
          </button>
          <button
            onClick={() => {
              if (results.text) {
                navigator.clipboard.writeText(results.text);
                alert('Text copied to clipboard!');
              }
            }}
            className="text-sm text-primary hover:text-indigo-700"
          >
            Copy All Text
          </button>
        </div>
      </div>
    </div>
  );
}