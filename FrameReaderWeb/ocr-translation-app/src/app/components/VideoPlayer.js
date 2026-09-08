'use client';

import { useState, useRef } from 'react';
import ReactPlayer from 'react-player';

export default function VideoPlayer({ file, onOCRComplete }) {
  const [capturedFrame, setCapturedFrame] = useState(null);
  const [isPlaying, setIsPlaying] = useState(true);
  const videoRef = useRef(null);
  const canvasRef = useRef(null);

  const captureFrame = () => {
    if (videoRef.current) {
      const canvas = canvasRef.current;
      const video = videoRef.current.getInternalPlayer();
      
      if (video) {
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        
        canvas.toBlob((blob) => {
          const frameFile = new File([blob], 'captured-frame.png', { type: 'image/png' });
          setCapturedFrame(URL.createObjectURL(blob));
          onOCRComplete(frameFile);
        }, 'image/png');
      }
    }
  };

  const handleProgress = (state) => {
    // You can add auto-capture logic here if needed
  };

  return (
    <div className="card">
      <div className="space-y-4">
        <div className="relative">
          <ReactPlayer
            ref={videoRef}
            url={URL.createObjectURL(file)}
            controls
            playing={isPlaying}
            onProgress={handleProgress}
            width="100%"
            height="auto"
          />
          <canvas ref={canvasRef} className="hidden" />
        </div>

        <div className="flex space-x-4">
          <button
            onClick={() => setIsPlaying(!isPlaying)}
            className="btn-primary"
          >
            {isPlaying ? 'Pause' : 'Play'}
          </button>
          <button
            onClick={captureFrame}
            className="btn-secondary"
          >
            Capture Current Frame
          </button>
        </div>

        {capturedFrame && (
          <div className="mt-4">
            <h4 className="font-medium text-gray-700 mb-2">Captured Frame:</h4>
            <img 
              src={capturedFrame} 
              alt="Captured frame" 
              className="max-w-full rounded-lg border border-gray-200"
            />
          </div>
        )}
      </div>
    </div>
  );
}