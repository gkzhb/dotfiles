// vim:fileencoding=utf-8:foldmethod=marker
// {{{1 options
settings.useNeovim = true

// {{{1 key mappings
// an example to create a new mapping `ctrl-y`

// mapkey('<ctrl-y>', 'Show me the money', function() {
//     Front.showPopup('a well-known phrase uttered by characters in the 1996 film Jerry Maguire (Escape to close).');
// });

// an example to replace `T` with `gt`, click `Default mappings` to see how `T` works.
// map('gt', 'T');

// an example to remove mapkey `Ctrl-i`
// unmap('<ctrl-i>');
const linkRefMap = {
    d: (url, title) => `[[${url}|${title}]]`, // dokuwiki link
    m: (url, title) => `[${title}](${url})`, // markdown link
    default: (url, title) => `${title} ${url}` // default format
}
mapkey('yr', 'copy link as ref', (key) => {
    let url = window.location.href;
    const title = document.title;
     if (url.indexOf(chrome.extension.getURL("/pages/pdf_viewer.html")) === 0) {
        url = window.location.search.substr(3);
    }
    if (key in linkRefMap) {
        Clipboard.write(linkRefMap[key](url, title));
    } else {
        Clipboard.write(linkRefMap.default(url, title));
    }
})
mapkey('q', 'close extension imcompatible alert', () => {
  const closeBtn = document.querySelector('#mainContainer .not-compatible__announce .ud__notice__close');
  closeBtn && closeBtn.click();
}, { domain: /feishu\.cn/i })

// use vim-style to cycle through ominibar
cmap('<Ctrl-n>', '<Tab>');
cmap('<Ctrl-p>', '<Shift-Tab>');

// {{1 color theme
// set theme
settings.theme = `
.sk_theme {
    font-family: Input Sans Condensed, Charcoal, sans-serif;
    font-size: 10pt;
    background: #24272e;
    color: #abb2bf;
}
.sk_theme tbody {
    color: #fff;
}
.sk_theme input {
    color: #d0d0d0;
}
.sk_theme .url {
    color: #61afef;
}
.sk_theme .annotation {
    color: #56b6c2;
}
.sk_theme .omnibar_highlight {
    color: #528bff;
}
.sk_theme .omnibar_timestamp {
    color: #e5c07b;
}
.sk_theme .omnibar_visitcount {
    color: #98c379;
}
.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #303030;
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
    background: #3e4452;
}
#sk_status, #sk_find {
    font-size: 15pt;
}`;
// click `Save` button to make above settings to take effect.</ctrl-i></ctrl-y>
