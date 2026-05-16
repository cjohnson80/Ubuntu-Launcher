
class ShortcutAppsModel {
  String? phone;
  String? message;
  String? camera;
  String? setting;
  List<String> pinnedApps;

  ShortcutAppsModel({
    this.phone,
    this.camera,
    this.message,
    this.setting,
    this.pinnedApps = const [],
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['phone'] = this.phone;
    data['message'] = this.message;
    data['camera'] = this.camera;
    data['setting'] = this.setting;
    data['pinnedApps'] = this.pinnedApps;
    return data;
  }
}
