'use client';

import { useState } from 'react';
import Image from 'next/image';

export default function ImageViewer({ file, onOCRComplete }) {
  const [imageUrl, setImageUrl] = useState(URL.createObjectURL(file));

  const handleOCR = () => {
    onOCRComplete(file);
  };

  return (
    <div className="card">
      <div className="space-y-4">
        <div className="relative">
          <img 
            src={imageUrl} 
            alt="Uploaded image" 
            className="max-w-full rounded-lg border border-gray-200"
            style={{ maxHeight: '500px' }}
          />
        </div>
        
        <div className="flex space-x-4">
          <button
            onClick={handleOCR}
            className="btn-primary"
          >
            Extract Text (OCR)
          </button>
        </div>
      </div>
    </div>
  );
}