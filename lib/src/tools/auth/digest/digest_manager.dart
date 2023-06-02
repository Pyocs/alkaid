import 'dart:collection';
import 'digest_message.dart';


class DigestManager {
  //key 为SessionID
  //如果nonce不对，则重新生成一个
  final HashMap<String,DigestMessage> _digests = HashMap();


  ///添加一个message
  ///如果缓存中有该sessionID的记录，则添加失败
  bool add(String sessionID,DigestMessage digestMessage) {
    if(contains(sessionID)) {
      return false;
    }
    _digests.addEntries({sessionID:digestMessage}.entries);
    return true;
  }

  bool remove(String sessionID) {
    return _digests.remove(sessionID) == null ? false : true;
  }

  DigestMessage? get(String sessionID) {
    return _digests[sessionID];
  }


  bool contains(String sessionID) {
    return _digests.containsKey(sessionID);
  }

  void clear() {
    _digests.clear();
  }
}