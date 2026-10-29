package com.example.frapp

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "frapp/native",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractVideoFrame" -> runInBackground(result) { extractVideoFrame(call) }
                "renderPdfPage" -> runInBackground(result) { renderPdfPage(call) }
                "pdfPageCount" -> runInBackground(result) { pdfPageCount(call) }
                else -> result.notImplemented()
            }
        }
    }

    private fun runInBackground(
        result: MethodChannel.Result,
        operation: () -> Any,
    ) {
        worker.execute {
            try {
                val value = operation()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error(
                        "native_media_failed",
                        error.message ?: "Native media processing failed.",
                        null,
                    )
                }
            }
        }
    }

    private fun extractVideoFrame(call: MethodCall): ByteArray {
        val path = call.argument<String>("path")
        val positionMs = call.argument<Number>("positionMs")?.toLong()
        if (path.isNullOrBlank() || positionMs == null || positionMs < 0) {
            throw IllegalArgumentException("A valid video path and position are required.")
        }

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val bitmap = retriever.getFrameAtTime(
                positionMs * 1_000,
                MediaMetadataRetriever.OPTION_CLOSEST,
            ) ?: throw IOException("No video frame exists at the selected position.")
            return try {
                bitmapToJpeg(bitmap)
            } finally {
                bitmap.recycle()
            }
        } finally {
            retriever.release()
        }
    }

    private fun renderPdfPage(call: MethodCall): ByteArray {
        val bytes = call.argument<ByteArray>("bytes")
        val pageIndex = call.argument<Int>("pageIndex") ?: 0
        if (bytes.isNullOrEmpty() || pageIndex < 0) {
            throw IllegalArgumentException("Valid PDF bytes and page index are required.")
        }

        val pdfFile = File.createTempFile("frapp-pdf-", ".pdf", cacheDir)
        try {
            FileOutputStream(pdfFile).use { it.write(bytes) }
            val descriptor = ParcelFileDescriptor.open(
                pdfFile,
                ParcelFileDescriptor.MODE_READ_ONLY,
            )
            return PdfRenderer(descriptor).use { renderer ->
                if (pageIndex >= renderer.pageCount) {
                    throw IndexOutOfBoundsException("The requested PDF page does not exist.")
                }
                renderer.openPage(pageIndex).use { page ->
                    val scale = minOf(
                        2.0,
                        3000.0 / maxOf(page.width, page.height),
                    )
                    val bitmap = Bitmap.createBitmap(
                        (page.width * scale).toInt().coerceAtLeast(1),
                        (page.height * scale).toInt().coerceAtLeast(1),
                        Bitmap.Config.ARGB_8888,
                    )
                    bitmap.eraseColor(android.graphics.Color.WHITE)
                    try {
                        page.render(
                            bitmap,
                            null,
                            null,
                            PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY,
                        )
                        bitmapToJpeg(bitmap)
                    } finally {
                        bitmap.recycle()
                    }
                }
            }
        } finally {
            pdfFile.delete()
        }
    }

    private fun pdfPageCount(call: MethodCall): Int {
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes.isNullOrEmpty()) {
            throw IllegalArgumentException("Valid PDF bytes are required.")
        }

        val pdfFile = File.createTempFile("frapp-pdf-", ".pdf", cacheDir)
        try {
            FileOutputStream(pdfFile).use { it.write(bytes) }
            val descriptor = ParcelFileDescriptor.open(
                pdfFile,
                ParcelFileDescriptor.MODE_READ_ONLY,
            )
            return PdfRenderer(descriptor).use { it.pageCount }
        } finally {
            pdfFile.delete()
        }
    }

    private fun bitmapToJpeg(bitmap: Bitmap): ByteArray {
        val output = ByteArrayOutputStream()
        if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 92, output)) {
            throw IOException("The image could not be encoded.")
        }
        return output.toByteArray()
    }
}
