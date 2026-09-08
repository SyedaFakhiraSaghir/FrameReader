'use client';

import { useState } from 'react';
import FileUpload from './components/FileUpload';
import VideoPlayer from './components/VideoPlayer';
import ImageViewer from './components/ImageViewer';
import DocumentViewer from './components/DocumentViewer';
import OcrResult from './components/OcrResult';

export default function Home() {
  const [file, setFile] = useState(null);
  const [fileType, setFileType] = useState(null);
  const [ocrResults, setOcrResults] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const handleFileUpload = async (uploadedFile) => {
    setFile(uploadedFile);
    setFileType(uploadedFile.type);
    setOcrResults(null);
    
    // Process OCR based on file type
    await processOCR(uploadedFile);
  };

  const processOCR = async (file) => {
    setIsProcessing(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('type', file.type);

      const response = await fetch('/api/ocr', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) throw new Error('OCR processing failed');
      
      const data = await response.json();
      setOcrResults(data);
    } catch (error) {
      console.error('OCR Error:', error);
      alert('Failed to process OCR. Please try again.');
    } finally {
      setIsProcessing(false);
    }
  };

  const renderFileViewer = () => {
    if (!file) return null;

    const fileTypeMap = {
      'video': VideoPlayer,
      'image': ImageViewer,
      'application/pdf': DocumentViewer,
    };

    const ViewerComponent = Object.keys(fileTypeMap).find(key => 
      fileType?.includes(key)
    ) ? fileTypeMap[Object.keys(fileTypeMap).find(key => 
      fileType?.includes(key)
    )] : null;

    if (!ViewerComponent) {
      return (
        <div className="card mt-6">
          <p className="text-gray-600">Unsupported file type</p>
        </div>
      );
    }

    return (
      <div className="mt-6">
        <ViewerComponent file={file} onOCRComplete={processOCR} />
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h2 className="text-3xl font-bold text-gray-900">Upload Your File</h2>
        <p className="mt-2 text-gray-600">Supports: Images, Videos, and Documents (PDF, Word, etc.)</p>
      </div>

      <FileUpload onFileUpload={handleFileUpload} />

      {isProcessing && (
        <div className="text-center py-4">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          <p className="mt-2 text-gray-600">Processing OCR...</p>
        </div>
      )}

      {file && renderFileViewer()}

      {ocrResults && (
        <div className="mt-6">
          <OcrResult 
            results={ocrResults} 
            onWordClick={(word) => {
              // Handle word click for translation
              console.log('Word clicked:', word);
            }}
          />
        </div>
      )}
    </div>
  );
}