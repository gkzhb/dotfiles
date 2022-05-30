const { addSearchAlias, mapkey, unmap, cmap, Clipboard, Front } = api;
// {{{1 options
settings.useNeovim = false;

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
  p: (url, title) => {
    // copy URL path
    const urlObj = new URL(url);
    return urlObj.pathname.slice(1);
  },
  default: (url, title) => `${title} ${url}`, // default format
};
mapkey("yr", "copy link as ref", (key) => {
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
});
mapkey(
  "q",
  "close extension imcompatible alert",
  () => {
    const closeBtn = document.querySelector(
      "#mainContainer .not-compatible__announce .ud__notice__close"
    );
    closeBtn && closeBtn.click();
  },
  { domain: /feishu\.cn/i }
);

// use vim-style to cycle through ominibar
cmap("<Ctrl-n>", "<Tab>");
cmap("<Ctrl-p>", "<Shift-Tab>");

// {{{2 searches
// remove old search keymaps
// baidu
unmap("ob");
// duckduckgo
unmap("od");
// wikipedia
unmap("oe");
// google
unmap("og");
// stackoverflow
unmap("os");
// bing
unmap("ow");
// youtube
unmap("oy");

// search with bilibili
addSearchAlias(
  "i",
  "bilibili",
  "https://search.bilibili.com/all?keyword=",
  "sbi",
  "https://s.search.bilibili.com/main/suggest?func=suggest&suggest_type=accurate&sub_type=tag&main_ver=v1&highlight=&userid=&bangumi_acc_num=1&special_acc_num=1&topic_acc_num=1&upuser_acc_num=3&tag_num=10&special_num=10&bangumi_num=10&upuser_num=3&jsonp=jsonp&term=",
  (ret) => {
    const rsp = JSON.parse(ret.text);
    if (rsp.code != "0") return [];
    return rsp.result.tag.map((el) => el.value);
  }
);
// search with zhihu
addSearchAlias(
  "zh",
  "zhihu",
  "https://www.zhihu.com/search?type=content&q=",
  "szh",
  "https://www.zhihu.com/api/v4/search/suggest?q=",
  (ret) => {
    const rsp = JSON.parse(ret.text);
    return rsp.suggest.map((el) => el.query);
  }
);
// rebind old searches
mapkey("osbd", "#8Open Search with alias baidu", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "b" });
});
mapkey("osbn", "#8Open Search with alias bing", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "w" });
});
mapkey("osd", "#8Open Search with alias duckduckgo", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "d" });
});
mapkey("osgg", "#8Open Search with alias google", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "g" });
});
mapkey("osgh", "#8Open Search with alias github", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "h" });
});
mapkey("oss", "#8Open Search with alias stackoverflow", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "s" });
});
mapkey("oswp", "#8Open Search with alias wikipedia", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "e" });
});
mapkey("osy", "#8Open Search with alias youtube", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "y" });
});

// new custom searches
mapkey("osbi", "#8Open Search with alias bilibili", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "i" });
});
mapkey("oszh", "#8Open Search with alias zhihu", () => {
  Front.openOmnibar({ type: "SearchEngine", extra: "zh" });
});

// {{{1 color theme
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
// vim:fileencoding=utf-8:foldmethod=marker:
