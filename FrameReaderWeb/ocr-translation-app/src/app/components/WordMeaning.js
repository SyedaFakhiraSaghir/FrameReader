'use client';

import { useState, useEffect } from 'react';

export default function WordMeaning({ word, onClose }) {
  const [meaning, setMeaning] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchMeaning = async () => {
      if (!word) return;
      
      setLoading(true);
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

        if (!response.ok) throw new Error('Failed to fetch meaning');
        
        const data = await response.json();
        setMeaning(data);
      } catch (error) {
        console.error('Error fetching meaning:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchMeaning();
  }, [word]);

  if (!word) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <div className="flex justify-between items-start mb-4">
          <h3 className="text-xl font-semibold text-gray-900">Word Meaning</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            ✕
          </button>
        </div>

        {loading ? (
          <div className="text-center py-8">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            <p className="mt-2 text-gray-600">Loading meaning...</p>
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <p className="text-lg font-medium text-gray-900">{word}</p>
              {meaning && (
                <p className="text-gray-600 mt-2">{meaning.translatedText}</p>
              )}
            </div>
            
            <div className="flex space-x-2">
              <button
                onClick={() => {
                  if (meaning) {
                    navigator.clipboard.writeText(meaning.translatedText);
                    alert('Copied to clipboard!');
                  }
                }}
                className="btn-primary text-sm"
              >
                Copy Translation
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}