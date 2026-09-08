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
    return new Blob([toUint8Array(bytes)], { type: 'image/jpeg' });
  }

  async function recognizeText(bytes, language) {
    if (!window.Tesseract) {
      throw new Error('The web OCR helper did not load. Refresh the page and try again.');
    }

    var result = await window.Tesseract.recognize(
      imageBlob(bytes),
      language === 'eng' || language === 'en' ? 'eng' : 'eng',
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
    var page = await pdfDocument.getPage((pageIndex || 0) + 1);
    var viewport = page.getViewport({ scale: 2 });
    var canvas = window.document.createElement('canvas');
    canvas.width = Math.ceil(viewport.width);
    canvas.height = Math.ceil(viewport.height);
    await page.render({ canvasContext: canvas.getContext('2d'), viewport: viewport }).promise;
    var blob = await new Promise(function (resolve) {
      canvas.toBlob(resolve, 'image/jpeg', 0.92);
    });
    if (!blob) throw new Error('The PDF page could not be rendered in the browser.');
    return new Uint8Array(await blob.arrayBuffer());
  }

  window.frameReaderNative = {
    recognizeText: recognizeText,
    renderPdfPage: renderPdfPage,
    extractVideoFrame: function () {
      return Promise.reject(new Error('Video frame extraction is not available in the browser yet.'));
    }
  };
}());
