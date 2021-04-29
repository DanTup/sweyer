/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// @dart = 2.12

import 'package:sweyer/sweyer.dart';

class Artist extends Content {
  @override
  final int id;
  final String artist;
  final int numberOfAlbums;
  final int numberOfTracks;

  @override
  List<Object> get props => [id];

  const Artist({
    required this.id,
    required this.artist,
    required this.numberOfAlbums,
    required this.numberOfTracks,
  });

  factory Artist.fromMap(Map map) {
    return Artist(
      id: map['id'] as int,
      artist: map['artist'] as String,
      numberOfAlbums: map['numberOfAlbums'] as int,
      numberOfTracks: map['numberOfTracks'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'artist': artist,
    'numberOfAlbums': numberOfAlbums,
    'numberOfTracks': numberOfTracks,
  };
}
