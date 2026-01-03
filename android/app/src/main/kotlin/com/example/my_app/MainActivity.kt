package com.example.my_app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Improve IME resize behavior on some Android builds by opting out of
    // edge-to-edge insets handling at the Activity level.
    WindowCompat.setDecorFitsSystemWindows(window, true)
  }
}
