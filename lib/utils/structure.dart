import 'dart:io';
import 'package:dmrtd/dmrtd.dart';
import 'package:eosio_passid_mobile_app/constants/constants.dart';
import 'package:intl/intl.dart';
import 'package:eosio_passid_mobile_app/utils/storage.dart';

class StringUtil {
  static String getWithoutTypeName<T>(T value){
    String str = value.toString();
    return str.substring(str.indexOf('.')+1, str.length);
  }
}

class EnumUtil {
  static T fromStringEnum<T>(Iterable<T> values, String stringType) {
    return values.firstWhere(
            (f)=> "${f.toString().substring(f.toString().indexOf('.')+1)}".toString()
            == stringType, orElse: () => null);
  }
}

class MapUtil {
  static bool contains<T>(Map structure, T requestType) {
    return structure.containsKey(requestType);
  }
}

enum Sex{ Male , Female }

enum NFCdeviceType { P , Unknown }

final Map<DgTag, String> mapDgTagName = {
  EfDG1.TAG : 'Ef.DG1',
  EfDG2.TAG : 'Ef.DG2',
  EfDG3.TAG : 'Ef.DG3',
  EfDG4.TAG : 'Ef.DG4',
  EfDG5.TAG : 'Ef.DG5',
  EfDG6.TAG : 'Ef.DG6',
  EfDG7.TAG : 'Ef.DG7',
  EfDG8.TAG : 'Ef.DG8',
  EfDG9.TAG : 'Ef.DG9',
  EfDG10.TAG : 'Ef.DG10',
  EfDG11.TAG : 'Ef.DG11',
  EfDG12.TAG : 'Ef.DG12',
  EfDG13.TAG : 'Ef.DG13',
  EfDG14.TAG : 'Ef.DG14',
  EfDG15.TAG : 'Ef.DG15',
  EfDG16.TAG : 'Ef.DG16'
};

bool badCertificateHostCheck(X509Certificate cert, String host, int port) {
  // TODO: in the future do not allow self signed certificates without signed host field.
  Storage storage = Storage();
  var server = storage.getServerCloud(networkTypeServer: NetworkTypeServer.MAIN_SERVER);
  if (server = null)
    throw ("Server is not found in the database");
  final srvUrl = server.selected != null? server.selected : server.servers.first;
  if (srvUrl != null) {
    return host ==  srvUrl; // TODO: certificate should be also checked in case bad selfsigned certificate is the case
  }
  return false;
}

String capitalize(final String string) {
  if (string == null || string.isEmpty) {
    return string;
  }
  final lstr = string.toLowerCase();
  return lstr[0].toUpperCase() + lstr.substring(1);
}

String formatProgressMsg(String message, int percentProgress) {
  final p = (percentProgress/20).round();
  final full  = '🔵 ' * p; // Note: Unicode 12 is not supported on android API 25 or lower
  final empty = '⚪️ ' * (5-p);
  return message + '\n\n' + full + empty;
}

String formatDgTagSet(final Set<DgTag> tags) {
  var str = '[';
  for(final t in tags) {
    str += mapDgTagName[t] + ', ';
  }
  return str.substring(0, str.length -2) + ']';
}

/// Test if internet connection is available.
/// Returns true if [host] if was successfully retrieved otherwise false.
Future<bool> testConnection({ String host = 'google.com' }) async
{
  try {
    final result = await InternetAddress.lookup(host);
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch(_){}
  return false;
}

class DateTimeUtil {
  static String current(DateFormat dateFormat) {
    final now = new DateTime.now();
    return dateFormat.format(now);
  }
}