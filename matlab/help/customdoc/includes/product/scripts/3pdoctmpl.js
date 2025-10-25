//===============================================================================
////==================Third Party Doc link templates=========================================

JST['thirdPartyTocTmpl'] = _.template(
       '<% for (var i = 0; i < thirdpartytbxes.length; i++) { %>' +
       '<% var tbx = thirdpartytbxes[i]; %>' +
       '<li style="display: list-item;"><a href="/static/help/<%= tbx.urlpath %>/<%= tbx.landingpage %>"><%= tbx.displayname %></a></li>' +
       '<% } %>'
);

JST['thirdPartyDocTmpl'] = _.template(
       '<% for (var i = 0; i < thirdpartytbxes.length; i++) { %>' +
       '<% var tbx = thirdpartytbxes[i]; %>' +
       '<% var helpLoc = tbx.helplocations[0]; %>' +
       '<div class="panel panel-default doc_panel doc_category_panel panel_installed">' +
       '<a href="/static/help/<%= tbx.urlpath %>/<%= helpLoc.contenttype %>/<%= helpLoc.landingpage %>" data-toggle="tooltip" data-placement="bottom auto" data-trigger="focus hover" data-container="body" title="" data-original-title="Installed Product">' +
       '<div class="panel-body"><span class="doc_panel_label"><%= tbx.displayname %></span></div>' +
       '</a>' +
       '</div>' +
       '<% } %>'
);

//===============================================================================
