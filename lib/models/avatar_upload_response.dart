class AvatarUploadResponse {
  final String uploadUrl;
  final String publicUrl;
  final String contentType;

  const AvatarUploadResponse({
    required this.uploadUrl,
    required this.publicUrl,
    required this.contentType,
  });

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResponse(
      uploadUrl: json['uploadUrl'],
      publicUrl: json['publicUrl'],
      contentType: json['contentType'],
    );
  }
}
