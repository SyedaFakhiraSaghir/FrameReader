'use client';

import { useState } from 'react';
import OcrProcessor from './OcrProcessor';

export default function ImageViewer({ file, onOCRComplete }) {
  const [imageUrl, setImageUrl] = useState(URL.createObjectURL(file));

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
        
        <OcrProcessor 
          imageFile={file}
          onComplete={onOCRComplete}
        />
      </div>
    </div>
  );
}