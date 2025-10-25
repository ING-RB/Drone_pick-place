function handleDocLinksClick3P(aTags) {
  let i;
  for (i = 0; i < aTags.length; i++) {
    aTags[i].onclick = function(evt) {
         const href = getHref(evt);
         if (href) {
             const hrefString = String(href);
             if (hrefString) {
                 const currentPageHost = window.location.host;
                 const currentPageProtocol = window.location.protocol;
                 const currentPage = window.location.href;
                 if (hrefString && hrefString.match(/^\s*matlab:.*/)) {
                     evt.stopImmediatePropagation();
                     const messageObj = {
                         "url" : hrefString,
                         "currenturl" : currentPage
                     };
                     const services = {
                        "messagechannel" : "matlab"
                     }
                     requestHelpService(messageObj, services, function() {});
                     return false;
                 } else if (hrefString && isCustomDocLink(hrefString)) {
                    evt.stopImmediatePropagation();
                     const messageObj = {
                         "url" : hrefString
                     };
                     const services = {
                        "messagechannel" : "custom_doc_link"
                     }
                     requestHelpService(messageObj, services, function (response) {
                        if (response && response.length > 0) {
                            const newUrl = response[0];
                            if (evt.ctrlKey) {
                                openUrlInNewTab(newUrl);
                            } else {
                                window.location.href = newUrl;
                            }
                        }
                     });
                     return false;
                 } else if (hrefString
                     && (hrefString.indexOf(currentPageProtocol) < 0 || hrefString.indexOf(currentPageHost) < 0)
                     && hrefString.indexOf('http') === 0
                     && (!isConnectorUrl(hrefString))
                     && (!isWebDocUrl(hrefString))) {
                         evt.stopImmediatePropagation();
                         const messageObj = {
                             "url" : hrefString
                         };
                         const services = {
                            "messagechannel" : "externalclick"
                         }
                         requestHelpService(messageObj, services , function() {});
                         return false;
                 } 
             }
         } 
    }                        
  }
}

function getHref(evt) {
    if (evt.target && ($(evt.target).attr("href"))) {
        return evt.target;
    }

    if (evt.currentTarget && ($(evt.currentTarget).attr("href"))) {
        return evt.currentTarget;
    }

    return null;
}

function handleContextMenu3P(iframeElement) {
    iframeElement.contentDocument.oncontextmenu = function (e) {
        e.preventDefault();
        const selectedUrl = getSelectedUrl(e.target);
        const messageObj = {
            url: selectedUrl
        };
        const services = {
            "messagechannel" : "custom_doc_link"
        }
        requestHelpService(messageObj, services, function (response) {
            if (response && response.length > 0) {
                const newUrl = response[0];
                openContextMenu3P(e, newUrl, iframeElement);
            }
        });
    };
}

function openContextMenu3P (e, selectedUrl, iframeElement) {
    const id = "docinfo_" + new Date().getTime();
    const selectedText = getSelectedText3P(iframeElement.contentDocument);        
    const browserContainerKey = 'help_browser_container';
    const isHideOpenNewTab = isSessionStorageItem('hide_new_tab_menu', 'true');
    const pageUrl = window.location.href;
    const offsets = iframeElement.getBoundingClientRect();
    const clientX = e.clientX + offsets.left;
    const clientY = e.clientY + offsets.top;

    const messageObj = {
        "domchannel" : 'domeventinfo',
        "title" : window.document.title,
        "url": pageUrl,
        "domevent": 'contextmenu',
        "eventData" : {
            "pageX": e.pageX,
            "pageY": e.pageY,
            "clientX": clientX,
            "clientY": clientY,
            "selectedText": selectedText,
            "selectedUrl": selectedUrl,
            "isHideOpenNewTab": isHideOpenNewTab,
            "helpBrowserContainer": getSessionStorageItem(browserContainerKey)
        },
        "id" : id
    };

    helpserviceIframePostMessage(messageObj);
}

function getSelectedText3P(contentDocument) {
    let text = "";
    if (contentDocument.getSelection) {
        text = contentDocument.getSelection().toString();
    }    
    return text;
}
