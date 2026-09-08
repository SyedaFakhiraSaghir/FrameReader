'use client';

import { useState, useEffect } from 'react';

export default function DocumentViewer({ file, onOCRComplete }) {
  const [content, setContent] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const readDocument = async () => {
      setIsLoading(true);
      try {
        // For PDF and other documents, we'll just show a preview and trigger OCR
        const text = await file.text();
        setContent(text.substring(0, 500) + '...');
      } catch (error) {
        console.error('Error reading document:', error);
      } finally {
        setIsLoading(false);
      }
    };

    readDocument();
  }, [file]);

  const handleOCR = () => {
    onOCRComplete(file);
  };

  return (
    <div className="card">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="font-medium text-gray-700">{file.name}</h4>
            <p className="text-sm text-gray-500">
              Size: {(file.size / 1024).toFixed(2)} KB
            </p>
          </div>
          <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
            {file.type}
          </span>
        </div>

        {isLoading ? (
          <div className="text-center py-8">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            <p className="mt-2 text-gray-600">Loading document...</p>
          </div>
        ) : (
          <div className="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
            <p className="text-sm text-gray-700 whitespace-pre-wrap">
              {content}
            </p>
          </div>
        )}

        <div className="flex space-x-4">
          <button
            onClick={handleOCR}
            className="btn-primary"
          >
            Extract Text (OCR)
          </button>
          <button
            onClick={() => window.open(URL.createObjectURL(file), '_blank')}
            className="btn-secondary"
          >
            Open Document
          </button>
        </div>
      </div>
    </div>
  );
}