var get_facet_label;
function populateResults(allSearchResults) {
    var sourceJson = getSourceJson(allSearchResults);  
    var sources = sourceJson.sources;
    var jsonObject = sourceJson.selectedsearchresults;

    var facetLabels = jsonObject.facetlabels ? jsonObject.facetlabels : {};
    populateLookupTable(facetLabels);
    
    if (jsonObject.responsetype === "noresults") {
        populateNoResults(jsonObject, sources);
    } else if (jsonObject.responsetype === "error") {
        displayError(jsonObject);
    } else {
        populateResultsList(jsonObject.results, jsonObject.searchtext);
        populateResultData(jsonObject.pagedata, sources);
        populateFacets(jsonObject.facets);
        populateSpellCheck(jsonObject);
        appendHighlightExpand(jsonObject.highlightexpand, jsonObject.searchtext);
    }
}

function getSourceJson(searchResults) {
    let allJson = {};
    let sources = [];

    if (Array.isArray(searchResults)) {
        searchResults = searchResults[0];
    }

    let sourceJson = {};
    sourceJson["source"] = searchResults.source;
    sourceJson["fullresultcount"] = searchResults.fullresultcount;
    sourceJson["searchterm"] = getSearchTerm(searchResults.searchtext);

    const selectedSource = (searchResults.source == searchResults.selectedsource);
    allJson["selectedsearchresults"] = searchResults;
    sources.push({"selectedsource":sourceJson});
    // Create JSON for the link to the alternate search source (MathWorks).
    let alternateSourceJson = {};
    alternateSourceJson["source"] = "mw";
    alternateSourceJson["searchterm"] = getSearchTerm(searchResults.searchtext);
    sources.push({"alternatesource":alternateSourceJson});

    // Sort sources alphabetically on the 'source' property, then reverse it to get mw first.
    sources.sort(function (a, b) {
        return (Object.values(a)[0].source.localeCompare(Object.values(b)[0].source));
    });
    sources.reverse();

    allJson["sources"] = sources;
    return allJson;
}

function getSearchTerm(searchText) {
    // Clean-up the search text, removing the facet data
    var typeIdx = searchText.indexOf("type");
    if (typeIdx >= 0) {
        return searchText.substring(0, typeIdx-1);
    }
    var prodIdx = searchText.indexOf("product");
    if (prodIdx >= 0) {
        return searchText.substring(0, prodIdx-1);
    }
    return searchText;
}

function populateResultsList(searchresults, searchTerm) {
    var highlightTerm = "";
    if (searchTerm && searchTerm.length > 0) {
        highlightTerm = searchTerm;
    } else if( $('#docsearch') && $('#docsearch').val() ){
        highlightTerm = $('#docsearch').val();
    }
    $('#wait').remove();

    var resultsHtml = '';
    resultsHtml = getSearchResultsHtml(searchresults, highlightTerm);

    var resultsDiv = $('#results_area');
    resultsDiv.html(resultsHtml);
}

function populateResultData(jsonObject, sourceJson) {
    var searchterm = jsonObject.searchterm;
    var productbreadcrumb = jsonObject.productbreadcrumb;
    var summarydata = jsonObject.summarydata;
    var footerdata = jsonObject.footerdata;
    var searchTextDescJson = getSearchTextDescJson(jsonObject, sourceJson);

    $('#docsearch').val(searchterm);
    tokenizeSearchText();

    var summaryHtml = '';
    summaryHtml = getSearchSummaryHtml(footerdata);

    if (searchTextDescJson.length == 1) {
        var searchingInfoDiv = $('#search_result_info_header');
        searchingInfoDiv.html(searchTextDescJson[0]);   
    } else if (searchTextDescJson.length > 1) {
        var searchingInfoDiv1 = $('#search_result_info_line1');
        searchingInfoDiv1.html(searchTextDescJson[0]);   
        var searchingInfoDiv2 = $('#search_result_info_line2');
        searchingInfoDiv2.html(searchTextDescJson[1]);   
    }

    var summaryDiv = $('#search_result_header');
    summaryDiv.html(summaryHtml);

    var footerHtml = '';
    footerHtml = getSearchFooterHtml(footerdata);

    var footerDiv = $('#search_result_footer');
    footerDiv.html(footerHtml);

    setPageTitle();
}

function getSearchTextDescJson(jsonObject, sourceJson) {
    if ((! sourceJson) || jQuery.isEmptyObject(sourceJson)) {
        return [jsonObject.searchtext];
    }

    let searchTextDescJson = [];
    searchTextDescJson.push(getSourceSearchTextDesc(sourceJson, 'selectedsource'));
    // Get the search text description for the alternatesource type.
    searchTextDescJson.push(getSourceSearchTextDesc(sourceJson, 'alternatesource'));

    return searchTextDescJson;
}

function getSourceSearchTextDesc(sourceJson, type) {
    // Find the element in the sourceJson array that contains a matching type 
    // (e.g., selectedsource, alternatesource).
    // If a matching type is found, use it to build and return the HTML for the 
    // search text description displayed at the top of the search results.
    var itemType = getSourceJsonForType(sourceJson, type);
    if (itemType) {
        return getFormattedSearchTextDesc(itemType, type);
    }

    // No matching type found in the sourceJson array. Return an empty string.
    return '';
}

function getFormattedSearchTextDesc(sourceJson, type) {
    switch (type) {
        case "selectedsource" : return getLocalizedString("search_results_for_source_" + sourceJson.source).replace(/\{0\}/, sourceJson.searchterm).replace(/\{1\}/, Number(sourceJson.fullresultcount).toLocaleString('en'));
        case "alternatesource" : return getLocalizedString("search_in_source_" + sourceJson.source).replace(/\{0\}/, getSearchInHyperlink(sourceJson));
        default : return '';
    }
}

function getSearchInHyperlink(sourceJson) {
    const searchTerm = sourceJson.searchterm;
    const source = sourceJson.source;
    const searchResultHref = _getSearchResultHref(searchTerm, source);
    return '<a href="' + searchResultHref + '">' + '<strong><i>' + searchTerm + '</i></strong>' + '</a>';
}

function _getSearchResultHref(searchTerm, source) {
    // Return the page populated in the template.
    const searchResultURL = new URL(searchPageParams.mwSearchPage);
    searchResultURL.searchParams.append("qdoc", searchTerm);
    searchResultURL.searchParams.append("selectedsource", source);
    searchResultURL.searchParams.append("newsource", source);
    return searchResultURL.href;
}

function populateFacets(facetJson) {
    var facetHtml = '';
    facetHtml = getFacetResultsHtml(facetJson);
    var facetDiv = $('#facets_area');
    facetDiv.html(facetHtml);
}

function displayError(error) {
    $('#docsearch').val(error.searchtext);
    var errorHtml = getErrorHtml(error.message);

    var errorDiv = $('#results_area');
    errorDiv.html(errorHtml);
    setPageTitle();
}

function populateNoResults(jsonObject, sources) {
    var jsonData = _getNoResultsData(jsonObject, sources);
    displayNoResults(jsonData);
    displaySearchTips(jsonData);
    displaySpellCheck(jsonData);
}

function _getNoResultsData(jsonData, sources) {
    var allJson = {};

    var noResultsJson = _getNoResultsMessages(jsonData, sources);
    var searchTipsJson = _getSearchTipsMessages(jsonData, sources);

    var dymMessageId = (jsonData.hasfacets && jsonData.hasfacets === true ?
                        'search_dym_message_results_without_filter_mw' :
                        'search_dym_message_results_mw');
    var stidQSParam = 'SRCH_DYM_NA';
    var spellCheckJson = _getSpellCheckMessages(jsonData.spellcheck, dymMessageId, stidQSParam);

    $.extend(allJson, jsonData);
    $.extend(allJson, noResultsJson);
    $.extend(allJson, searchTipsJson);
    $.extend(allJson, spellCheckJson);

    return allJson;
}

function _getNoResultsMessages(jsonData, sources) {
    var noResultsJson = {};
    var message = _getNoResultsMessage(jsonData, sources);
    var altSearchMessage = _getAltSearchMessage(sources);
    noResultsJson.message = message;
    noResultsJson.alternatesearchmessage = altSearchMessage;
    return noResultsJson;
}

function _getAltSearchMessage(sourceJson) {
    if ((! sourceJson) || jQuery.isEmptyObject(sourceJson)) {
        return '';
    }

    var alternateSourceJson = getSourceJsonForType(sourceJson, 'alternatesource');
    if (! alternateSourceJson) {
        return '';
    }

    var messageId = "search_in_source_" + alternateSourceJson.source;
    var searchHyperlink = getSearchInHyperlink(alternateSourceJson);
    var message = getLocalizedString(messageId).replace(/\{0\}/, searchHyperlink);

    return message;
}

function _getNoResultsMessage(jsonData, sources) {
    var baseMessageId = _getNoResultsMessageId(jsonData, sources);
    var message = getLocalizedString(baseMessageId).replace(/\{0\}/, jsonData.spellcheck.searchtext);
    return message;    
}

function _getNoResultsMessageId(jsonData, sources) {
    var baseMessageId = (jsonData.hasfacets === false ? "search_no_results_tips_message" : "search_no_results_tips_message_with_filter");

    var sourceIds = _getSourceIds(jsonData, sources);    
    if ((! sourceIds) || jQuery.isEmptyObject(sourceIds)) {
        baseMessageId = baseMessageId + '_mw';
        return baseMessageId;
    }

    for(var i = 0; i < sourceIds.length; i++) {
        var sourceId = sourceIds[i];
        baseMessageId = baseMessageId + '_' + sourceId;
    }

    return baseMessageId;
}

function _getSourceIds(jsonData, sourceJson) {
    if ((! sourceJson) || jQuery.isEmptyObject(sourceJson)) {
        return '';
    }

    let sourceIds = [];
    const selectedSourceJson = getSourceJsonForType(sourceJson, 'selectedsource');
    sourceIds.push(selectedSourceJson.source);

    const additionalIdJson = getSourceJsonForType(sourceJson, 'alternatesource');
    sourceIds.push(additionalIdJson.source);

    // Sort sources alphabetically on the 'source' property, then reverse it to get mw first.
    sourceIds.sort(function (a, b) {
        return (Object.values(a)[0].localeCompare(Object.values(b)[0]));
    });
    sourceIds.reverse();

    return sourceIds;
}

function getSourceJsonForType(sourceJson, type) {
    // Iterate over the sourceJson array. Find and return the array element containing
    // a matching type (e.g., selectedsource, alternatesource).
    for (const item of sourceJson) {
        const itemType = item[type];
        if (itemType) {
            return itemType;
        }
    }

    // No matching type found in sourceJson array. Return undefined.
    return undefined;
}

function _getSearchTipsMessages(jsonData, sources) {
    var searchTipsJson = {};

    var suggestionsheader = getLocalizedString("search_no_results_tips_header");
    var suggestions = [];
    var ctr = 0;
    var tip = getLocalizedString("search_no_results_tip_" + (ctr+1));
    while (tip && tip.length > 0) {
        suggestions[ctr] = tip;
        ctr++;
        tip = getLocalizedString("search_no_results_tip_" + (ctr+1));
    }

    searchTipsJson.suggestionsheader = suggestionsheader;
    searchTipsJson.suggestions = suggestions;

    return searchTipsJson;
}

function _getSpellCheckMessages(spellcheck, dymMessageId, stidQSParam) {
    var dymJson = {};

    var spellCheckHyperlink = _getSpellCheckHyperlink(spellcheck, stidQSParam);
    var dymMessage = getLocalizedString(dymMessageId).replace(/\{0\}/, spellCheckHyperlink).replace(/\{1\}/, spellcheck.spellcheckresultcount);

    spellcheck.didyoumeanmessage = dymMessage;
    
    dymJson.spellcheck = spellcheck;

    return dymJson;
}

function _getSpellCheckHyperlink(spellcheck, stidQSParam) {
    var searchTerm = encodeURIComponent(spellcheck.spellcheck);
    var searchText = spellcheck.spellcheck;
    return '<a href="searchresults.html?qdoc=' + searchTerm + '&s_tid=' + stidQSParam + '">' + searchText + '</a>';
}

function displayNoResults(jsonData) {
    if (jsonData.alternatesearchmessage && jsonData.alternatesearchmessage.length > 0) {
        var searchingInfoDiv1 = $('#search_result_info_line1');
        searchingInfoDiv1.html(jsonData.message);   
        var searchingInfoDiv2 = $('#search_result_info_line2');
        searchingInfoDiv2.html(jsonData.alternatesearchmessage);   
    } else {
        var searchingInfoDiv = $('#search_result_info_header');
        searchingInfoDiv.html(jsonData.message);  
    }
}

function displaySearchTips(jsonData) {
    var messageDiv = $('#results_area');
    messageDiv.empty();
    $('#docsearch').val(jsonData.searchtext);
    tokenizeSearchText();
    messageDiv.append(getSuggestionsListHtml(jsonData));
    setPageTitle();
}

function setPageTitle() {
    document.title = getLocalizedString("search_results") + " - " + $("#docsearch").val();
}

function tokenizeSearchText() {
    $('form#docsearch_form').tokenize({
        fields: ["product", "category", "type"],
        remove_if_empty: true,
        label_function: get_facet_label
    });
}

function populateSpellCheck(jsonData) {
    var allJson = {};

    var dymMessageId = ('search_dym_message_results');
    var stidQSParam = 'SRCH_DYM_LS';
    var spellCheckJson = _getSpellCheckMessages(jsonData.spellcheck, dymMessageId, stidQSParam);

    $.extend(allJson, jsonData);
    $.extend(allJson, spellCheckJson);

    displaySpellCheck(allJson);
}

function displaySpellCheck(jsonData) {
    if(jsonData === undefined) {
        return;
    }

    var spellcheckHtml = '';
    spellcheckHtml = getSpellCheckResultsHtml(jsonData);

    var messageDiv = $('#search_result_dym_header');
    messageDiv.html(spellcheckHtml);
}

function populateLookupTable(facetLabelJson) {

    var labels = {};
    for (var facetLabel in facetLabelJson) {
        if (facetLabelJson.hasOwnProperty(facetLabel)) {
            labels[facetLabelJson[facetLabel].field + ":" + 
                    facetLabelJson[facetLabel].value] = facetLabelJson[facetLabel].label;
        }
    }
    get_facet_label = function (token) {
        var labelDataString = sessionStorage.getItem('facetlookuptable');
        if(labelDataString !== undefined && labelDataString != null) {
            var labelData = JSON.parse(labelDataString);
            if (labelData !== undefined && labelData != null) {
                return labelData[token.field + ":" + token.value];                
            }
        }
        return labels[token.field + ":" + token.value];
    }
    
    if(!$.isEmptyObject(labels)) {
        sessionStorage.setItem('facetlookuptable', JSON.stringify(labels));
    }
}

let installedSearchURL;

$(document).ready(function() {
    const installedSearchLocation = window.location.href.split('?')[0];
    installedSearchURL = new URL(installedSearchLocation);
    let searchData = parseQueryString();
    setCookiesFromParams(searchData);
    populateStrings();
    if (! searchData["selectedsource"]) {
        searchData["selectedsource"] = "mw";
    } 
    var supportedSources = getSupportedSources(searchData.selectedsource);
    getSearchResults(searchData, supportedSources);
});

function getSupportedSources(selectedSource) {
    var supportedSources;
    var searchSource = getSessionStorageValue('searchsource');
    if (searchSource) {
        searchSource = searchSource.replace("+", " ");
        supportedSources = searchSource.split(" ");
    } else {
        supportedSources = [selectedSource];
    }
    return supportedSources;
}

function getSessionStorageValue(key) {
    var value;
    try {
        value = sessionStorage.getItem(key);
    } catch (e) {
        value = null;
    }
    return value;
}

function getSearchResults(searchData, supportedSources) {   
    var allDeferreds = [];

    var i;
    for (i = 0; i < supportedSources.length; i++) { 
        var source = supportedSources[i];
        var deferredSearchData = {};
        $.extend(deferredSearchData, searchData);
        $.extend(deferredSearchData, {"source":source});
        var searchResultsDeferred = getSearchDeferred(deferredSearchData);
        allDeferreds[i] = searchResultsDeferred;
    }

    $.when.apply($,allDeferreds).then(function() {
         var allSearchResults = $.makeArray(arguments);
         populateResults(allSearchResults);
    });    
}

function getSearchDeferred(searchData) {
    var deferred = $.Deferred(function() {});
    var services = {
        'messageservice' : 'help/search/query',
        'messagechannel':'docsearch',
        'localservice': '/help/search/query',
        'webservice': getSearchWebServiceUrl()
	};
    var errorhandler = function() {
        deferred.reject();
    }
    var successhandler = function(data) {
        deferred.resolve(data);
    }
    requestHelpService(searchData, services, successhandler, errorhandler);
    return deferred;
}

function getSearchWebServiceUrl() {
    var release = "";
    const regex = /.*\/help\/releases\/(R20\d\d[ab])\/.*/;
    const found = document.location.href.match(regex);
    if (found != null && found.length >= 2) {
        release = "/" + found[1];
    }
    return "/help/search/json/doccenter/en" + release;    
}

function getDocReleaseFromSearchBox() {
    var localeEl = $("#docsearch_form");
    return localeEl.attr('data-release');
}

function populateStrings() {
    var footerElt;
    if (! isFileProtocol()) {
        // MATLAB views documentation served by the connector.
        footerElt = $(".matlab_footer");
    } else {
        // Polyspace views documentation served off of the file system.
        footerElt = $(".polyspace_footer");
    }
    footerElt.removeClass("off");
    $(footerElt).find("#acknowledgments").text(getLocalizedString("acknowledgments"));
    $(footerElt).find("#trademarks").text(getLocalizedString("trademarks"));
    $(footerElt).find("#patents").text(getLocalizedString("patents"));
    $(footerElt).find("#terms_of_use").text(getLocalizedString("terms_of_use"));
}

function isFileProtocol() {
    var prtcl = document.location.protocol;
    return prtcl.match(/file/);
}

// Copyright 2024 The MathWorks, Inc.
