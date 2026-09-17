/**
 * The catalog's README fragments are third-party markup, so they are cut
 * down to plain document structure before they reach the page: known
 * tags only, links and images with http(s) targets only, no attributes
 * beyond those, nothing that runs or embeds. Anything unknown is
 * unwrapped to its text, except the few elements whose content is not
 * prose, which go entirely.
 */

const KEPT = new Set([
  "p",
  "br",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "ul",
  "ol",
  "li",
  "a",
  "strong",
  "b",
  "em",
  "i",
  "code",
  "pre",
  "img",
  "blockquote",
  "hr",
  "del",
  "s",
  "kbd",
  "table",
  "thead",
  "tbody",
  "tr",
  "th",
  "td",
]);

const DROPPED = new Set(["script", "style", "iframe", "object", "embed", "svg", "math", "template", "video", "audio"]);

export function sanitizeDescription(html: string): string {
  const doc = new DOMParser().parseFromString(html, "text/html");
  clean(doc.body);
  return doc.body.innerHTML;
}

function clean(parent: Element): void {
  for (const node of Array.from(parent.childNodes)) {
    if (node.nodeType === Node.TEXT_NODE) {
      continue;
    }
    if (node.nodeType !== Node.ELEMENT_NODE) {
      node.remove();
      continue;
    }
    const element = node as Element;
    const tag = element.tagName.toLowerCase();
    if (DROPPED.has(tag)) {
      element.remove();
      continue;
    }
    if (!KEPT.has(tag)) {
      clean(element);
      element.replaceWith(...Array.from(element.childNodes));
      continue;
    }
    // The raw attribute, not the resolved property: a relative link would
    // resolve against the app's own origin and pass as a web URL.
    const href = tag === "a" ? element.getAttribute("href") : null;
    const src = tag === "img" ? element.getAttribute("src") : null;
    for (const attribute of Array.from(element.attributes)) {
      element.removeAttribute(attribute.name);
    }
    if (tag === "a" && isWebUrl(href)) {
      element.setAttribute("href", href);
    }
    if (tag === "img") {
      if (!isWebUrl(src)) {
        element.remove();
        continue;
      }
      element.setAttribute("src", src);
      element.setAttribute("alt", "");
      element.setAttribute("loading", "lazy");
      element.setAttribute("referrerpolicy", "no-referrer");
    }
    clean(element);
  }
}

function isWebUrl(value: string | null): value is string {
  return value !== null && (value.startsWith("https://") || value.startsWith("http://"));
}
