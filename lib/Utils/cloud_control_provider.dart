import 'package:flutter/cupertino.dart';

import '../Models/cloud_control.dart';

LoftifyControlProvider controlProvider = LoftifyControlProvider();

class LoftifyControlProvider with ChangeNotifier {
  LoftifyControl? _cloudControl;

  LoftifyControl get originalCloudControl =>
      (_cloudControl ?? LoftifyControl.defaultCloudControl);

  set originalCloudControl(LoftifyControl? value) {
    _cloudControl = value;
    notifyListeners();
  }

  LoftifyControl? _globalControl;

  LoftifyControl get globalControl =>
      (_globalControl ?? LoftifyControl.defaultCloudControl);

  set globalControl(LoftifyControl? value) {
    if (value != null) {
      // 仓库归属是本地属性：云控配置（含历史缓存与彩蛋手动覆盖）不得
      // 改写报告 BUG、仓库主页和更新检查的目标，永远指向本 fork。
      final defaults = LoftifyControl.defaultCloudControl.contacts!;
      final contacts = value.contacts;
      if (contacts != null) {
        contacts.issueUrl = defaults.issueUrl;
        contacts.repoUrl = defaults.repoUrl;
        contacts.releaseUrl = defaults.releaseUrl;
      }
    }
    _globalControl = value;
    notifyListeners();
  }
}
