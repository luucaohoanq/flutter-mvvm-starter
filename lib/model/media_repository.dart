import 'package:flutter_mvvm_starter/model/media.dart';
import 'package:flutter_mvvm_starter/model/services/base_service.dart';
import 'package:flutter_mvvm_starter/model/services/media_service.dart';

class MediaRepository {
  final BaseService _mediaService = MediaService();

  Future<List<Media>> fetchMediaList(String value) async {
    dynamic response = await _mediaService.getResponse(value);
    final jsonData = response['results'] as List;
    List<Media> mediaList =
        jsonData.map((tagJson) => Media.fromJson(tagJson)).toList();
    return mediaList;
  }
}
