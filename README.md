# Ursinia

## Important Links

- [Website](https://ursinia.net)
- [Source Repository](https://git.sr.ht/~jamesaorson/ursinia.net)
- [CI/CD Deployment](https://builds.sr.ht/~jamesaorson/ursinia.net/commits/main/deploy.yml)

## Developing

### Writing Scheme template (preferred)

In [`templates/`](./templates/) is a copy of the site hierarchy, containing `*.scm` files.

Currently, each `*.scm` file maps `1:1` with a file of the name `*`, so `todo/index.html.scm` maps to `todo/index.html`

#### HTML

For HTML, there is a helper library present for constructing pages.

Here is an example, complete with demonstrating how to iterate over a list to generate HTML pages:

```scheme
(use-modules (scripts lib html))

(render-template "Ursinia - Example"
                 `((header (div (@ (id "header"))
                                (span (@ (id "header-sitemap"))
                                      (a (@ (id "header-sitemap-link")
                                            (href "/sitemap"))
                                         #\↤ " " (code "sitemap")))))
                   (h1 (a (@ (id "title")
                             (href "#title")
                             (class "list-item-internal-link"))
                          "Example"))
                   (div (p "Why hello there!"))
                   (div (ul ,(map-in-order (lambda (link)
                                             (let ([href (car link)]
                                                   [text (cdr link)])
                                               `(li (a (@ (href ,href))
                                                       ,text))))
                                           '(["/something" . "Dude"]
                                             ["/else" . "Oh Yeah"]
                                             ["/why-not" . "Oh boy"]))))))
```

The resulting output is minified, but if that output is then formatted, it would look like so:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Ursinia - Example</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" type="image/x-icon" href="/shared/favicons/favicon.ico" />
    <link rel="stylesheet" href="/shared/styles/openword-theme.css" />
    <link rel="stylesheet" href="/styles/main.css" />
  </head>
  <body>
    <header>
      <div id="header">
        <span id="header-sitemap"
          ><a id="header-sitemap-link" href="/sitemap"
            >&#8612; <code>sitemap</code></a
          ></span
        >
      </div>
    </header>
    <h1>
      <a id="title" href="#title" class="list-item-internal-link">Example</a>
    </h1>
    <div><p>Why hello there!</p></div>
    <div>
      <ul>
        <li><a href="/something">Dude</a></li>
        <li><a href="/else">Oh Yeah</a></li>
        <li><a href="/why-not">Oh boy</a></li>
      </ul>
    </div>
  </body>
</html>
```

### Other

Just print to stdout whatever you want in the file and it will render verbatim.

For example:

```scheme
;; templates/todo/some.txt.scm
(use-modules (ice-9 format))

(format #t "Some text file~%Idk, ~d" 5)
```

would result in `wwwroot/todo/some.txt:

```plaintext
Some text file
Idk, 5
```

### Writing raw HTML

Write your code directly in [`wwwroot`](./wwwroot/)

## Deployment

This is done automatically when a push is done to the `main` branch.
