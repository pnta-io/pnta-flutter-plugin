
import 'pnta_flutter_platform_interface.dart';

class PntaFlutter {
  Future<String?> getPlatformVersion() {
    return PntaFlutterPlatform.instance.getPlatformVersion();
  }
}
