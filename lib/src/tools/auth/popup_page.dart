import 'dart:convert';
import 'dart:io';

import '../../../alkaid.dart';
import 'auth_options.dart';


//弹出游览器默认窗口登陆
AuthCallback popupPage({String eventName = "token"}) {
  return (request, HttpResponse response,String jwt) {
    var evt = json.encode(eventName);
    var detail = json.encode({'detail':jwt});

    response.headers.contentType = ContentType.html;
    response.write('''
          <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Authentication Success</title>
          <script>
            var ev = new CustomEvent($evt, $detail);
            window.opener.dispatchEvent(ev);
            window.close();
          </script>
        </head>
        <body>
          <h1>Authentication Success</h1>
          <p>
            Now logging you in... If you continue to see this page, you may need to enable JavaScript.
          </p>
        </body>
      </html>
    ''');
    return Future.value(AlkaidStatus.finish);
  };
}
