/// This app's route configuration.
library angel.routes;

import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'controllers/controllers.dart' as Controllers;

final List<String> _IMAGE_EXTENSIONS = <String>[
  "jpg",
  "jpeg",
  "png",
  "gif",
  "tiff",
  "ico"
];
final int _NEWLINE = "\n".codeUnits.first;

configureBefore(Angel app) async {}

/// Put your app routes here!
configureRoutes(Angel app) async {
  app.post("/upload", (RequestContext req, res) async {
    if (req.files.isEmpty || req.files[0].data.isEmpty)
      throw new AngelHttpException.BadRequest(
          message: "Please upload a file. :)");

    var file = req.files[0];
    var nLines = file.data.where((n) => n == _NEWLINE).length;
    res
      ..header("Content-Type", "text/html")
      ..write('''
    <!DOCTYPE html>
    <html>
        <head>
            <title>${file.filename}</title>
        </head>
        <body>
          <h1>${file.filename}</h1>''');

    if (_isImage(file)) {
      var base64String = BASE64.encode(file.data);
      res.write('<img src="data:${file.mimeType};base64,$base64String" />');
    }

    res
      ..write('''
          <table>
            <tr>
              <td><b>Size:</b></td>
              <td>${file.data.length / 1000}kb</td>
            </tr>
            <tr>
              <td><b>MIME Type:</b></td>
              <td>${file.mimeType}</td>
            </tr>
            <tr>
              <td><b>Number of Lines:</b></td>
              <td>${nLines + 1}</td>
            </tr>
          </table>
        </body>
    </html>
    ''')
      ..end();
  });

  await app.configure(new VirtualDirectory());
}

configureAfter(Angel app) async {
  // 404 handler
  app.after.add((req, ResponseContext res) async {
    throw new AngelHttpException.NotFound();
  });

  // Default error handler
  app.onError(
      (e, req, res) async => res.render("error", {"message": e.message}));
}

configureServer(Angel app) async {
  await configureBefore(app);
  await configureRoutes(app);
  await app.configure(Controllers.configureServer);
  await configureAfter(app);
}

bool _isImage(file) {
  var ext = file.filename.split(".").last;
  return _IMAGE_EXTENSIONS.contains(ext);
}
