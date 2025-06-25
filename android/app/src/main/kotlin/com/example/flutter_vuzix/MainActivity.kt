package com.example.flutter_vuzix

import android.content.*
import android.os.Build
import com.vuzix.sdk.speechrecognitionservice.VuzixSpeechClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/* ---------- Channel-Namen ---------- */
private const val CMD_CHANNEL = "vuzix/speech"        // Flutter → Android
private const val EVT_CHANNEL = "vuzix/speech/events" // Android → Flutter

/* ---------- Dictation-Intents von Vuzix Voice Input ---------- */
private const val ACTION_DICT_SENTENCE = "com.vuzix.VOICE_INPUT.RESULT" // ganzer Satz
private const val ACTION_DICT_WORD     = "com.vuzix.VOICE_INPUT.WORD"   // Wort-für-Wort
private const val EXTRA_TEXT           = "EXTRA_TEXT"                   // Text-Payload

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler {

    /* ---------------- Utils: Gerät erkennen ------------------- */
    private fun isEmulator(): Boolean {
        val fp = Build.FINGERPRINT.lowercase()
        val mdl = Build.MODEL.lowercase()
        val brd = Build.BRAND.lowercase()
        val prd = Build.PRODUCT.lowercase()
        return fp.contains("generic") || fp.contains("vbox") ||
               mdl.contains("google_sdk") || mdl.contains("emulator") ||
               brd.startsWith("generic") && prd.contains("sdk")
    }

    private fun isVuzixDevice(): Boolean =
        Build.MANUFACTURER.equals("vuzix", ignoreCase = true) && !isEmulator()

    /* ---------------- Klassen­variablen ----------------------- */
    private lateinit var cmdChannel: MethodChannel
    private var evtSink: EventChannel.EventSink? = null
    private var speech: VuzixSpeechClient? = null
    private var vuzixReceiver: BroadcastReceiver? = null

    /* ---------------------- Flutter-Engine -------------------- */
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)

        // Method / Event-Channels einrichten
        cmdChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CMD_CHANNEL)
        cmdChannel.setMethodCallHandler(this)

        EventChannel(engine.dartExecutor.binaryMessenger, EVT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) { evtSink = sink }
                override fun onCancel(args: Any?)                               { evtSink = null  }
            })

        /* --------- Vuzix-SDK nur auf echter Vuzix-Hardware ------- */
        if (isVuzixDevice()) {
            // Offline-Recognizer für Kommandos
            speech = VuzixSpeechClient(this).apply {
                VuzixSpeechClient.EnableRecognizer(applicationContext, true)
            }

            // BroadcastReceiver für Kommandos + Dictation
            val filter = IntentFilter().apply {
                addAction(VuzixSpeechClient.ACTION_VOICE_COMMAND)
                addAction(ACTION_DICT_SENTENCE)
                addAction(ACTION_DICT_WORD)
            }

            vuzixReceiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context?, i: Intent?) {
                    when (i?.action) {
                        VuzixSpeechClient.ACTION_VOICE_COMMAND -> {
                            i.getStringExtra(VuzixSpeechClient.PHRASE_STRING_EXTRA)
                                ?.let { evtSink?.success(it) }
                        }
                        ACTION_DICT_WORD, ACTION_DICT_SENTENCE -> {
                            i.getStringExtra(EXTRA_TEXT)
                                ?.let { evtSink?.success(it) }
                        }
                    }
                }
            }
            registerReceiver(vuzixReceiver, filter)
        }
        /* -- andernfalls: nichts tun, App läuft im Emulator weiter -- */
    }

    /* -------------------- Flutter → Android ------------------- */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "registerPhrases" -> {
                if (isVuzixDevice()) {
                    (call.arguments as List<*>).forEach {
                        speech?.insertPhrase(it.toString().lowercase())
                    }
                }
                result.success(null)
            }
            "startDictation" -> {
                if (isVuzixDevice()) sendBroadcast(Intent("com.vuzix.VOICE_INPUT.START"))
                result.success(null)
            }
            "stopDictation" -> {
                if (isVuzixDevice()) sendBroadcast(Intent("com.vuzix.VOICE_INPUT.STOP"))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /* -------------- Aufräumen, wenn Activity endet ------------- */
    override fun onDestroy() {
        if (isVuzixDevice()) {
            try { unregisterReceiver(vuzixReceiver) } catch (_: Exception) {}
            speech = null
        }
        super.onDestroy()
    }
}
