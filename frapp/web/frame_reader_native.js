(function () {
  'use strict';

  var pdfModulePromise;

  function toUint8Array(value) {
    if (value instanceof Uint8Array) return value;
    if (value instanceof ArrayBuffer) return new Uint8Array(value);
    if (ArrayBuffer.isView(value)) {
      return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
    }
    if (Array.isArray(value)) return new Uint8Array(value);
    throw new Error('The browser did not receive valid file bytes.');
  }

  function imageBlob(bytes) {
    return new Blob([toUint8Array(bytes)]);
  }

  async function recognizeText(bytes, language) {
    if (!window.Tesseract) {
      throw new Error('The web OCR helper did not load. Refresh the page and try again.');
    }

    var languageCode = {
      en: 'eng',
      ur: 'urd',
      ar: 'ara',
      es: 'spa',
      fr: 'fra',
      de: 'deu',
      zh: 'chi_sim',
      hi: 'hin'
    }[language] || 'eng';
    var result = await window.Tesseract.recognize(
      imageBlob(bytes),
      languageCode,
      {
        logger: function () {},
        workerPath: 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/worker.min.js',
        corePath: 'https://cdn.jsdelivr.net/npm/tesseract.js-core@5.1.1/tesseract-core.wasm.js',
        langPath: 'https://tessdata.projectnaptha.com/4.0.0'
      }
    );
    var data = result.data || {};
    var words = (data.words || []).map(function (word) {
      var box = word.bbox || {};
      return {
        text: word.text || '',
        x: box.x0 || 0,
        y: box.y0 || 0,
        width: Math.max(0, (box.x1 || 0) - (box.x0 || 0)),
        height: Math.max(0, (box.y1 || 0) - (box.y0 || 0)),
        confidence: (word.confidence || 0) / 100
      };
    });

    return {
      text: data.text || '',
      words: words,
      imageWidth: data.image ? data.image.width : 0,
      imageHeight: data.image ? data.image.height : 0
    };
  }

  async function pdfjs() {
    if (!pdfModulePromise) {
      pdfModulePromise = import(
        'https://cdn.jsdelivr.net/npm/pdfjs-dist@4.10.38/build/pdf.min.mjs'
      );
    }
    return pdfModulePromise;
  }

  async function renderPdfPage(bytes, pageIndex) {
    var pdf = await pdfjs();
    var pdfDocument = await pdf.getDocument({ data: toUint8Array(bytes) }).promise;
    try {
      if (pageIndex < 0 || pageIndex >= pdfDocument.numPages) {
        throw new Error('The requested PDF page does not exist.');
      }
      var page = await pdfDocument.getPage(pageIndex + 1);
      var sourceViewport = page.getViewport({ scale: 1 });
      var scale = Math.min(
        2,
        3000 / Math.max(sourceViewport.width, sourceViewport.height)
      );
      var viewport = page.getViewport({ scale: scale });
      var canvas = window.document.createElement('canvas');
      canvas.width = Math.ceil(viewport.width);
      canvas.height = Math.ceil(viewport.height);
      await page.render({ canvasContext: canvas.getContext('2d'), viewport: viewport }).promise;
      var blob = await new Promise(function (resolve) {
        canvas.toBlob(resolve, 'image/jpeg', 0.92);
      });
      if (!blob) throw new Error('The PDF page could not be rendered in the browser.');
      return new Uint8Array(await blob.arrayBuffer());
    } finally {
      await pdfDocument.destroy();
    }
  }

  async function pdfPageCount(bytes) {
    var pdf = await pdfjs();
    var pdfDocument = await pdf.getDocument({ data: toUint8Array(bytes) }).promise;
    try {
      return pdfDocument.numPages;
    } finally {
      await pdfDocument.destroy();
    }
  }

  async function extractVideoFrame(url, positionMs) {
    var video = window.document.createElement('video');
    video.preload = 'auto';
    video.muted = true;
    video.playsInline = true;
    video.src = url;

    try {
      await new Promise(function (resolve, reject) {
        video.addEventListener('loadedmetadata', resolve, { once: true });
        video.addEventListener('error', function () {
          reject(new Error('The selected video could not be opened.'));
        }, { once: true });
        video.load();
      });

      var duration = Number.isFinite(video.duration) ? video.duration : 0;
      var position = Math.max(0, Math.min(positionMs / 1000, duration));
      if (Math.abs(video.currentTime - position) > 0.001) {
        await new Promise(function (resolve, reject) {
          video.addEventListener('seeked', resolve, { once: true });
          video.addEventListener('error', function () {
            reject(new Error('The video could not seek to the selected frame.'));
          }, { once: true });
          video.currentTime = position;
        });
      }

      var canvas = window.document.createElement('canvas');
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      if (!canvas.width || !canvas.height) {
        throw new Error('The selected video frame has no image data.');
      }
      var context = canvas.getContext('2d');
      if (!context) throw new Error('The video frame could not be rendered.');
      context.drawImage(video, 0, 0, canvas.width, canvas.height);

      var blob = await new Promise(function (resolve) {
        canvas.toBlob(resolve, 'image/jpeg', 0.92);
      });
      if (!blob) throw new Error('The video frame could not be encoded.');
      return new Uint8Array(await blob.arrayBuffer());
    } finally {
      video.pause();
      video.removeAttribute('src');
      video.load();
    }
  }

  window.frameReaderNative = {
    recognizeText: recognizeText,
    renderPdfPage: renderPdfPage,
    pdfPageCount: pdfPageCount,
    extractVideoFrame: extractVideoFrame
  };
}());
