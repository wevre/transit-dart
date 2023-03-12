class Link {
  final Uri href;
  final String rel;
  final String? name;
  final String? render;
  final String? prompt;

  Link(this.href, this.rel, {this.name, this.render, this.prompt});

  Map toMap() {
    return {
      'href': href.toString(),
      'rel': rel,
      if (null != name) 'name': name,
      if (null != render) 'render': render,
      if (null != prompt) 'prompt': prompt,
    };
  }
}
