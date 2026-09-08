'use client';

import { useDropzone } from 'react-dropzone';
import { useState } from 'react';

export default function FileUpload({ onFileUpload }) {
  const [dragActive, setDragActive] = useState(false);

  const onDrop = (acceptedFiles) => {
    if (acceptedFiles.length > 0) {
      onFileUpload(acceptedFiles[0]);
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'],
      'video/*': ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv'],
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
    },
    maxSize: 50 * 1024 * 1024, // 50MB
  });

  return (
    <div 
      {...getRootProps()} 
      className={`upload-zone ${isDragActive ? 'border-primary bg-blue-50' : ''}`}
    >
      <input {...getInputProps()} />
      <div className="space-y-4">
        <svg 
          className="mx-auto h-12 w-12 text-gray-400"
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path 
            strokeLinecap="round" 
            strokeLinejoin="round" 
            strokeWidth="2" 
            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
          />
        </svg>
        <div>
          <p className="text-lg font-medium text-gray-700">
            {isDragActive ? 'Drop your file here' : 'Drag & drop your file here'}
          </p>
          <p className="text-sm text-gray-500 mt-2">
            or click to browse files
          </p>
          <p className="text-xs text-gray-400 mt-2">
            Supported: Images (PNG, JPG, GIF), Videos (MP4, AVI, MOV), Documents (PDF, DOC, DOCX)
          </p>
          <p className="text-xs text-gray-400">Max size: 50MB</p>
        </div>
      </div>
    </div>
  );
}