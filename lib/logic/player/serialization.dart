/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sweyer/sweyer.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Interface to manage serialization.
///
/// [R] denotes type that is returned from [read] method.
/// [S] denotes type that has to be provided to the [save] method.
abstract class JsonSerializer<R, S> {
  const JsonSerializer();

  String get fileName;

  /// Value that will be written in [init] method.
  S get initialValue;

  /// Create file json if it does not exists or of it is empty then write to it empty array.
  Future<void> init() async {
    final file = await getFile();
    if (!await file.exists()) {
      await file.create();
      await file.writeAsString(jsonEncode(initialValue));
    } else if (await file.readAsString() == '') {
      await file.writeAsString(jsonEncode(initialValue));
    }
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  /// Reads json and returns decoded data.
  Future<R> read();

  /// Serializes provided data into json.
  Future<void> save(S data);
}

/// Used to serialize queue.
///
/// Saves only songs ids, so you have to search indexes in 'all' queue to restore.
class QueueSerializer extends JsonSerializer<List<Map<String, dynamic>>, List<Song>> {
  const QueueSerializer(this.fileName);

  @override
  final String fileName;
  @override
  List<Song> get initialValue => [];

  /// Returns a list of song ids.
  @override
  Future<List<Map<String, dynamic>>> read() async {
    try {
      final file = await getFile();
      final jsonContent = await file.readAsString();
      final list = jsonDecode(jsonContent) as List;
      if (list.isNotEmpty) {
        // Initially the queue was saved as list of ids.
        // This ensures there will be no errors in case someone migrates from
        // the old version.
        if (list[0] is int) {
          return [];
        }
      }
      return list.cast<Map<String, dynamic>>();
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in QueueSerializer.read, fileName: $fileName',
      );
      ShowFunctions.instance.showError(
        errorDetails: buildErrorReport(ex, stack),
      );
      debugPrint('$fileName: Error reading songs json, setting to empty songs list');
      return [];
    }
  }

  /// Serializes provided songs into json as array of such entries:
  ///
  /// ```ts
  /// {
  ///   "id": number,
  ///   "origin_type": null | "album",
  ///   "origin_id": null | number,
  /// }
  /// ```
  /// 
  /// * `id` is song id
  /// * `origin_type` is the persistent queue type (if any)
  /// * `origin_id` is the persistent queue type (if any)
  @override
  Future<void> save(List<Song> data) async {
    final file = await getFile();
    final json = jsonEncode(data.map((song) {
      final origin = song.origin;
      return {
        'id': song.id,
        if (origin != null)
          'origin_type': origin is Album ? 'album' : throw UnimplementedError(),
        if (origin != null)
          'origin_id': origin.id,
      };
    }).toList());
    await file.writeAsString(json);
    // debugPrint('$fileName: json saved');
  }
}

/// Used to serialize song id map.
class IdMapSerializer extends JsonSerializer<Map<String, int>, Map<String, int>> {
  IdMapSerializer._();
  static final instance = IdMapSerializer._();

  @override
  String get fileName => 'id_map.json';
  @override
  Map<String, int> get initialValue => {};

  @override
  Future<Map<String, int>> read() async {
    try {
      final file = await getFile();
      final jsonContent = await file.readAsString();
      return jsonDecode(jsonContent).cast<String, int>();
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in IdMapSerializer.read, fileName: $fileName',
      );
      ShowFunctions.instance.showError(
        errorDetails: buildErrorReport(ex, stack),
      );
      debugPrint('$fileName: Error reading songs json, setting to empty songs list');
      return {};
    }
  }

  /// Serializes provided map as id map.
  /// Used on dart side to saved cleared map, in other cases used on native.
  @override
  Future<void> save(Map<String, int> data) async {
    final file = await getFile();
    await file.writeAsString(jsonEncode(data));
    // debugPrint('$fileName: json saved');
  }
}
