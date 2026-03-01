/// Request model for update profile API call
class UpdateProfileRequestModel {
  final String? fullName;
  final String? phone;
  final String? favoriteGame;
  final String? place;
  final String? currentPassword;
  final String? changePassword;

  UpdateProfileRequestModel({
    this.fullName,
    this.phone,
    this.favoriteGame,
    this.place,
    this.currentPassword,
    this.changePassword,
  });

  /// Convert to JSON for API request (for non-multipart requests)
  Map<String, dynamic> toJson() {
    return {
      if (fullName != null && fullName!.isNotEmpty) 'fullName': fullName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (favoriteGame != null && favoriteGame!.isNotEmpty) 'favoriteGame': favoriteGame,
      if (place != null && place!.isNotEmpty) 'place': place,
      if (currentPassword != null && currentPassword!.isNotEmpty) 'currentPassword': currentPassword,
      if (changePassword != null && changePassword!.isNotEmpty) 'changePassword': changePassword,
    };
  }

  /// Convert to Map for FormData fields
  Map<String, dynamic> toFormDataMap() {
    final map = <String, dynamic>{};
    
    if (fullName != null && fullName!.isNotEmpty) {
      map['fullName'] = fullName;
    }
    if (phone != null && phone!.isNotEmpty) {
      map['phone'] = phone;
    }
    if (favoriteGame != null && favoriteGame!.isNotEmpty) {
      map['favoriteGame'] = favoriteGame;
    }
    if (place != null && place!.isNotEmpty) {
      map['place'] = place;
    }
    if (currentPassword != null && currentPassword!.isNotEmpty) {
      map['currentPassword'] = currentPassword;
    }
    if (changePassword != null && changePassword!.isNotEmpty) {
      map['changePassword'] = changePassword;
    }
    
    return map;
  }
}
