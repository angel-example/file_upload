/// This app's route configuration.
library angel.routes;

import 'dart:convert';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:angel_file_security/angel_file_security.dart';
import 'package:charcode/ascii.dart';
import 'package:html_builder/elements.dart';
import 'package:html_builder/html_builder.dart';
import 'package:path/path.dart' as p;
import 'controllers/controllers.dart' as Controllers;

const List<String> _IMAGE_EXTENSIONS = const [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.tiff',
  '.ico'
];

configureBefore(Angel app) async {}

/// Put your app routes here!
configureRoutes(Angel app) async {
  final StringRenderer renderer = new StringRenderer(pretty: false);

  app.chain(restrictFileUploads(maxFiles: 1)).post("/upload",
      (RequestContext req, ResponseContext res) async {
    if (req.files.isEmpty || req.files[0].data.isEmpty)
      throw new AngelHttpException.badRequest(
          message: "Please upload a file. :)");

    var file = req.files[0];
    var nLines = file.data.where((n) => n == $lf).length + 1;

    List<Node> childNodes = [
      h1(children: [text(file.filename)])
    ];

    if (_isImage(file)) {
      var base64String = BASE64.encode(file.data);
      childNodes.add(img(src: 'data:${file.mimeType};base64,$base64String'));
    }

    childNodes.add(table(children: [
      tr(children: [
        td(children: [
          b(children: [text('Size:')])
        ]),
        td(children: [text('${file.data.length / 1000}kb')])
      ]),
      tr(children: [
        td(children: [
          b(children: [text('MIME type:')])
        ]),
        td(children: [text(file.mimeType)])
      ]),
      tr(children: [
        td(children: [
          b(children: [text('Number of Lines:')])
        ]),
        td(children: [text('${nLines + 1}')])
      ]),
    ]));

    var doc = html(children: [
      head(children: [
        title(children: [text(file.filename)])
      ]),
      body(children: childNodes)
    ]);

    res
      ..contentType = ContentType.HTML
      ..write(renderer.render(doc))
      ..end();
  });

  await app.configure(new VirtualDirectory());
  app.responseFinalizers.add(gzip());
}

configureAfter(Angel app) async {
  // 404 handler
  app.after.add((req, ResponseContext res) async {
    throw new AngelHttpException.notFound();
  });

  // Default error handler
  app.errorHandler =
      (e, req, res) async => res.render("error", {"message": e.message});
}

configureServer(Angel app) async {
  await configureBefore(app);
  await configureRoutes(app);
  await app.configure(Controllers.configureServer);
  await configureAfter(app);
}

bool _isImage(FileUploadInfo file) {
  return _IMAGE_EXTENSIONS.contains(p.extension(file.filename));
}
