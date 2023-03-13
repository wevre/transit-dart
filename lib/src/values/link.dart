class Link {
  final Map<String, String> m;

  Link(String href, String rel, {String? name, String? render, String? prompt})
      : m = {} {
    m['href'] = href;
    m['rel'] = rel;
    if (null != name) {
      m['name'] = name;
    }
    if (null != render) {
      if ('link' == render || 'image' == render) {
        m['render'] = render;
      } else {
        throw Exception('Value of render must be "link" or "image"');
      }
    }
    if (null != prompt) {
      m['prompt'] = prompt;
    }
  }

  Map toMap() => m;

  Link.fromMap(this.m);
}
