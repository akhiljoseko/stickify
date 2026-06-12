package co.inevitablesoftware.stickify

import android.content.Context
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "co.inevitablesoftware.stickify/custom_print"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "printPdf") {
                val name = call.argument<String>("name") ?: "Document"
                val bytes = call.argument<ByteArray>("bytes")
                val widthMm = call.argument<Double>("width") ?: 210.0
                val heightMm = call.argument<Double>("height") ?: 297.0

                if (bytes == null) {
                    result.error("INVALID_ARGUMENT", "Bytes cannot be null", null)
                    return@setMethodCallHandler
                }

                try {
                    printPdfNatively(name, bytes, widthMm, heightMm)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PRINT_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun printPdfNatively(name: String, bytes: ByteArray, widthMm: Double, heightMm: Double) {
        val printManager = getSystemService(Context.PRINT_SERVICE) as PrintManager
        
        // Convert millimeters to mils: mils = mm / 25.4 * 1000
        val widthMils = (widthMm / 25.4 * 1000.0).toInt()
        val heightMils = (heightMm / 25.4 * 1000.0).toInt()

        val customMediaSize = PrintAttributes.MediaSize(
            "custom_sticker_sheet",
            "Custom Sticker Sheet",
            widthMils,
            heightMils
        )

        val attrib = PrintAttributes.Builder()
            .setMediaSize(customMediaSize)
            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
            .build()

        val adapter = object : PrintDocumentAdapter() {
            override fun onLayout(
                oldAttributes: PrintAttributes?,
                newAttributes: PrintAttributes?,
                cancellationSignal: CancellationSignal?,
                callback: LayoutResultCallback?,
                extras: Bundle?
            ) {
                if (cancellationSignal?.isCanceled == true) {
                    callback?.onLayoutCancelled()
                    return
                }

                val info = PrintDocumentInfo.Builder(name)
                    .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                    .build()
                callback?.onLayoutFinished(info, true)
            }

            override fun onWrite(
                pages: Array<out PageRange>?,
                destination: ParcelFileDescriptor?,
                cancellationSignal: CancellationSignal?,
                callback: WriteResultCallback?
            ) {
                var output: FileOutputStream? = null
                try {
                    output = FileOutputStream(destination?.fileDescriptor)
                    output.write(bytes)
                    callback?.onWriteFinished(arrayOf(PageRange.ALL_PAGES))
                } catch (e: Exception) {
                    callback?.onWriteFailed(e.toString())
                } finally {
                    try {
                        output?.close()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }

        printManager.print(name, adapter, attrib)
    }
}
