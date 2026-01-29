/// Request model for update profile API call
class UpdateProfileRequestModel {
  final String? name;
  final String? number;
  final String? favouriteGame;
  final String? place;
  final String? avatar;
  final String? currentPassword;
  final String? changePassword;

  UpdateProfileRequestModel({
    this.name,
    this.number,
    this.favouriteGame,
    this.place,
    this.avatar,
    this.currentPassword,
    this.changePassword,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (number != null) 'number': number,
      if (favouriteGame != null) 'favouriteGame': favouriteGame,
      if (place != null) 'place': place,
      if (avatar != null) 'avatar': avatar,
      if (currentPassword != null) 'currentPassword': currentPassword,
      if (changePassword != null) 'changePassword': changePassword,
    };
  }

  /// Create from parameters
  factory UpdateProfileRequestModel.fromMap(Map<String, dynamic> map) {
    return UpdateProfileRequestModel(
      name: map['name'] ?? map['fullName'],
      number: map['number'],
      favouriteGame: map['favouriteGame'] ?? map['favoriteGame'],
      place: map['place'] ?? map['location'],
      avatar: map['avatar'],
      currentPassword: map['currentPassword'] ?? map['oldPassword'],
      changePassword: map['changePassword'] ?? map['newPassword'],
    );
  }
}
