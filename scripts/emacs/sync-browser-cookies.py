#!/usr/bin/env python3

# ~/.emacs.d/url/cookies
# https://github.com/borisbabic/browser_cookie3


# ;; A cookie is stored internally as a vector of 7 slots
# ;; [ url-cookie NAME VALUE EXPIRES LOCALPART DOMAIN SECURE ]

from datetime import datetime
from browser_cookie3 import Vivaldi


TEMPLATE = """
;; Emacs-W3 HTTP cookies file
;; Automatically generated file!!! DO NOT EDIT!!!
;;   file content imported from browser cookies on {}

(setq url-cookie-storage
{}
)

(setq url-cookie-secure-storage
{}
)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; End:
"""

DOMAINFILTER = []
# DOMAINFILTER = ['github.com', 'gitlab.com']


def domainIsInteresting(domain):
    if len(DOMAINFILTER) == 0:
        return True

    for df in DOMAINFILTER:
        if domain.endswith(df):
            return True

    return False


def getCookies(cj, Secure):
    cookies = {}
    for cookie in cj:

        # apparently `url-cookie-secure-storage` is not used? so load cookies in both stores for now
        #if cookie.secure is not Secure:
        #    continue

        if cookie.domain not in cookies:
            cookies[cookie.domain] = []
            
        value = cookie.value.replace('"', '')
        cline = '[url-cookie "{}"  "{}"  "{}"  "{}"  "{}"  {}]'.format(cookie.name, value, cookie.expires, cookie.path, cookie.domain, 't' if cookie.secure else 'nil')
        cookies[cookie.domain].append(cline)

    cstore = []
    for domain, clines in cookies.items():
        if not domainIsInteresting(domain):
            continue

        if len(cstore) == 0:
            cstore.append('  \'(')
        cstore.append('    ("{}"'.format(domain))
        for cline in clines:
            cstore.append("     " + cline)
        cstore.append("    )")

    if len(cstore) != 0:
        cstore.append('  )')
    else:
        cstore.append('\'nil')

    return cstore


def main():
    cj = Vivaldi().load()
    # print(Vivaldi().find_cookie_file())

    cookies = getCookies(cj, False)
    cookies_secure = getCookies(cj, True)

    cfile = TEMPLATE.format(datetime.now().strftime('%Y-%m-%d %H:%M:%S'), 
                            '\n'.join(cookies), 
                            '\n'.join(cookies_secure))

    print(cfile)



if __name__ == '__main__':
    # python3 sync-browser-cookies.py > ~/.config/emacs/.local/cache/url/cookies
    main()


