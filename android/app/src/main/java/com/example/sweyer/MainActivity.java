package com.example.sweyer;

import android.content.Context;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import com.ryanheise.audioservice.AudioServicePlugin;

public class MainActivity extends FlutterActivity {
   @Override
   public FlutterEngine provideFlutterEngine(Context context) {
      return AudioServicePlugin.getFlutterEngine(context);
   }
}