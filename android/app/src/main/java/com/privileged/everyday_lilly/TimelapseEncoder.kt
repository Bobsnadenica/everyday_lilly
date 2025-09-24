package com.privileged.everyday_lilly

import android.content.Context
import android.util.Log
import android.graphics.*
import android.media.*
import java.io.File
import kotlin.math.roundToInt

/**
 * Simple timelapse encoder using MediaCodec + MediaMuxer.
 * Draws each image into a Surface-backed encoder at the requested fps.
 */
object TimelapseEncoder {

    data class Params(
        val imagePaths: List<String>,
        val outPath: String,
        val fps: Double = 1.0,          // frames per second
        val width: Int? = null,         // optional; default = first image width (clamped to even)
        val height: Int? = null,        // optional; default = first image height (clamped to even)
        val bitrate: Int = 6_000_000    // ~6Mbps H.264
    )

    @Throws(Exception::class)
    fun encode(context: Context, p: Params): String {
        Log.d("TimelapseEncoder", "Starting timelapse encoding with ${p.imagePaths.size} images")
        require(p.imagePaths.isNotEmpty()) { "No images provided" }

        val firstBmp = BitmapFactory.decodeFile(p.imagePaths.first())
            ?: throw IllegalArgumentException("Failed to decode first image")

        var outW = p.width ?: firstBmp.width
        var outH = p.height ?: firstBmp.height
        if (outW % 2 == 1) outW -= 1
        if (outH % 2 == 1) outH -= 1
        if (outW <= 0 || outH <= 0) throw IllegalArgumentException("Invalid output size")
        Log.d("TimelapseEncoder", "Output size: ${outW}x${outH}, fps=${p.fps}")

        val outFile = File(p.outPath)
        outFile.parentFile?.mkdirs()
        if (outFile.exists()) outFile.delete()
        Log.d("TimelapseEncoder", "Output file will be saved to: ${outFile.absolutePath}")

        val mime = MediaFormat.MIMETYPE_VIDEO_AVC
        val format = MediaFormat.createVideoFormat(mime, outW, outH).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar)
            setInteger(MediaFormat.KEY_BIT_RATE, minOf(p.bitrate, 2_000_000))
            setInteger(MediaFormat.KEY_FRAME_RATE, p.fps.roundToInt().coerceAtLeast(1))
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
        }

        val codec = MediaCodec.createEncoderByType(mime)
        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val muxer = MediaMuxer(outFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        var trackIndex = -1
        var muxerStarted = false
        val bufferInfo = MediaCodec.BufferInfo()

        fun drain(endOfStream: Boolean = false) {
            while (true) {
                val outIndex = codec.dequeueOutputBuffer(bufferInfo, 10_000)
                when {
                    outIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        if (!endOfStream) break
                    }
                    outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        if (muxerStarted) throw RuntimeException("Format changed twice")
                        val newFormat = codec.outputFormat
                        trackIndex = muxer.addTrack(newFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                    outIndex >= 0 -> {
                        if (!muxerStarted) throw RuntimeException("Muxer not started")
                        val encoded = codec.getOutputBuffer(outIndex)
                            ?: throw RuntimeException("encoderOutputBuffer $outIndex was null")
                        if (bufferInfo.size > 0) {
                            encoded.position(bufferInfo.offset)
                            encoded.limit(bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(trackIndex, encoded, bufferInfo)
                        }
                        codec.releaseOutputBuffer(outIndex, false)
                        if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) return
                    }
                }
            }
        }

        fun bitmapToNV12(bmp: Bitmap, width: Int, height: Int): ByteArray {
            val argb = IntArray(width * height)
            bmp.getPixels(argb, 0, width, 0, 0, width, height)
            val ySize = width * height
            val uvSize = ySize / 2
            val yuv = ByteArray(ySize + uvSize) // NV12: Y + interleaved UV
            var yIndex = 0
            var uvIndex = ySize
            var idx = 0
            for (j in 0 until height) {
                for (i in 0 until width) {
                    val c = argb[idx++]
                    val r = (c ushr 16) and 0xFF
                    val g = (c ushr 8) and 0xFF
                    val b = c and 0xFF
                    val y = ((0.299 * r + 0.587 * g + 0.114 * b)).toInt().coerceIn(0, 255)
                    val u = ((-0.169 * r - 0.331 * g + 0.500 * b) + 128).toInt().coerceIn(0, 255)
                    val v = (( 0.500 * r - 0.419 * g - 0.081 * b) + 128).toInt().coerceIn(0, 255)
                    yuv[yIndex++] = y.toByte()
                    if ((j % 2 == 0) && (i % 2 == 0)) {
                        yuv[uvIndex++] = u.toByte() // U
                        yuv[uvIndex++] = v.toByte() // V
                    }
                }
            }
            return yuv
        }

        try {
            codec.start()
            val dstRect = Rect(0, 0, outW, outH)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
            var ptsUs = 0L
            val frameUs = (1_000_000.0 / p.fps).toLong().coerceAtLeast(1L)

            for (path in p.imagePaths) {
                Log.d("TimelapseEncoder", "Processing image: $path")
                val src = BitmapFactory.decodeFile(path) ?: continue

                val srcRect = Rect(0, 0, src.width, src.height)
                val srcAspect = src.width / src.height.toFloat()
                val dstAspect = outW / outH.toFloat()
                if (srcAspect > dstAspect) {
                    val newW = (src.height * dstAspect).toInt()
                    val x = (src.width - newW) / 2
                    srcRect.set(x, 0, x + newW, src.height)
                } else if (srcAspect < dstAspect) {
                    val newH = (src.width / dstAspect).toInt()
                    val y = (src.height - newH) / 2
                    srcRect.set(0, y, src.width, y + newH)
                }

                val frameBmp = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
                val c = Canvas(frameBmp)
                c.drawColor(Color.BLACK, PorterDuff.Mode.SRC)
                c.drawBitmap(src, srcRect, dstRect, paint)
                src.recycle()

                val yuv = bitmapToNV12(frameBmp, outW, outH)
                frameBmp.recycle()

                val inIndex = codec.dequeueInputBuffer(10_000)
                if (inIndex >= 0) {
                    val inBuf = codec.getInputBuffer(inIndex) ?: continue
                    inBuf.clear()
                    inBuf.put(yuv)
                    codec.queueInputBuffer(inIndex, 0, yuv.size, ptsUs, 0)
                    Log.d("TimelapseEncoder", "Queued frame, ptsUs=$ptsUs, bytes=${yuv.size}")
                    ptsUs += frameUs
                }
                drain(false)
                Log.d("TimelapseEncoder", "Queued frame, ptsUs=$ptsUs, bytes=${yuv.size}")
            }

            val inIndex = codec.dequeueInputBuffer(10_000)
            if (inIndex >= 0) {
                codec.queueInputBuffer(inIndex, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            }
            drain(true)

        } catch (e: Exception) {
            Log.e("TimelapseEncoder", "Encoding failed: ${e.message}", e)
            throw e
        } finally {
            try { codec.stop() } catch (_: Throwable) {}
            try { codec.release() } catch (_: Throwable) {}
            try { muxer.stop() } catch (_: Throwable) {}
            try { muxer.release() } catch (_: Throwable) {}
            Log.d("TimelapseEncoder", "Encoding complete, video path: ${outFile.absolutePath}")
        }

        return outFile.absolutePath
    }
}