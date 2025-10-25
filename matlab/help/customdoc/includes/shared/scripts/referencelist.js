function getProductFilteredReferenceList(mystylesheetLocation, mysourceLocation, product_help_location, top_nav_li, doccentertype, langcode) {

    // Call product filter web service with two callback functions.
    // The first callback runs after we get data, while the second
    // runs if we cannot get data.
    var services = {
      "messagechannel":"prodfilter",
      "localservice":"/help/search/prodfilter",
      "webservice": getProdFilterWebServiceUrl()
    }
    requestHelpService({}, services,
        function(data) {
            // Reference list with product filter
            var prodlist = data.prodnavlist;
            if (typeof prodlist === "string") {
                prodlist = $.parseJSON(prodlist);
            }        
            var productfilter_shortnames = new Array(prodlist.length);
            for (var i = 0; i < prodlist.length; i++) {
              productfilter_shortnames[i] = prodlist[i].shortname;
            }

            var xmlbaseuri;
            if (product_help_location.startsWith("supportpkg/")) {
                xmlbaseuri = document.location.href; // URI to support package location
                saxonJsTransformCall(mystylesheetLocation, product_help_location, top_nav_li, doccentertype, langcode, productfilter_shortnames, xmlbaseuri, 'sourceLocation', mysourceLocation);
            } else {
                var docsetJsonToXmlDeferred = getDocsetJsonToXmlDeferred(mysourceLocation);
                $.when(docsetJsonToXmlDeferred).done(function(originalXmlData) {
                    xmlbaseuri = document.location.href.replace(/\/help\/.*$/,"/help/referencelist.html"); // URI to direct child of help/
                    saxonJsTransformCall(mystylesheetLocation, product_help_location, top_nav_li, doccentertype, langcode, productfilter_shortnames, xmlbaseuri, 'sourceText', originalXmlData);
                });
            }            
        },
        function() {
            // Reference list without product filter
            var xmlbaseuri;
            if (product_help_location.startsWith("supportpkg/")) {
                xmlbaseuri = document.location.href; // URI to support package location
                saxonJsTransformCall(mystylesheetLocation, product_help_location, top_nav_li, doccentertype, langcode, [], xmlbaseuri, 'sourceLocation', mysourceLocation);
            } else {
                xmlbaseuri = document.location.href.replace(/\/help\/.*$/,"/help/referencelist.html"); // URI to direct child of help/
                var docsetJsonToXmlDeferred = getDocsetJsonToXmlDeferred(mysourceLocation);
                $.when(docsetJsonToXmlDeferred).done(function(originalXmlData) {
                    saxonJsTransformCall(mystylesheetLocation, product_help_location, top_nav_li, doccentertype, langcode, [], xmlbaseuri, 'sourceText', originalXmlData);
                });
            }
        }
    );

}

function saxonJsTransformCall(mystylesheetLocation, product_help_location, top_nav_li, doccentertype, langcode, productfilter_shortnames, xmlbaseuri, source_parameter, mysource_value) {

    var transformObj = {
      stylesheetLocation: mystylesheetLocation,
      stylesheetParams: {
        "product_help_location": product_help_location,
        "top_nav_li": top_nav_li,
        "doccentertype": doccentertype,
        "loctype": getLoctype(),
        "langcode": langcode,
        "productfilter_shortnames": productfilter_shortnames,
        "xmlbaseuri": xmlbaseuri
      }
    };
    transformObj[source_parameter] = mysource_value;

    SaxonJS.transform(transformObj); // Consider adding 'async' as 2nd argument. Reference: http://saxonica.com/saxon-js/documentation/index.html#!api/transform/execution
}


function getDocsetJsonToXmlDeferred(mysourceLocation) {
   var deferred = $.Deferred(function() {});
    var errorhandler = function(err, textStatus, jqXHR) {
        deferred.reject();
    }
    var successhandler = function(data) {
        var docset = {};
        docset['documentation_set'] = {'format': 'helpcenter',
           'product_list': data.documentation_set.product_list//,
           //'addon_list': data.documentation_set.addon_list
        };
        var xmldata = cleanupXml(convertObjectToXml(docset));
        deferred.resolve(xmldata);
    }
    
    var docsetJson = mysourceLocation.split("docset.xml")[0] + "docset.json";
    $.getJSON(docsetJson)
    .done(successhandler)
    .fail(errorhandler);

    return deferred;
}

function getLoctype() {
	// Check for presence of MW_Doc_Template cookie
	const cookieRegexp = /MW_Doc_Template="?([^;"]*)/;
	var cookies = document.cookie;
	var matches = cookieRegexp.exec(cookies);

	if (matches != null) {
		var docCookie = matches[1];
		var parts = docCookie.split(/\|\|/);
		if (parts[0].indexOf("PRODUCT") == -1) { return "web"; };
	 };
	 return "product";
}

function cleanupXml(xmlstring) {
  return '<?xml version="1.0" encoding="UTF-8"?>' + xmlstring;
}

function convertObjectToXml(obj) {
   var xml = '';
    for (var prop in obj) {
        if (obj[prop] instanceof Array) {
            xml += '<' + prop + '>';
            for (var array in obj[prop]) {
                xml += convertObjectToXml(new Object(obj[prop][array]));
            }
            xml += '</' + prop + '>';
        } else {
            xml += '<' + prop + '>';
            typeof obj[prop] == 'object' ? xml += convertObjectToXml(new Object(obj[prop])) : xml += obj[prop];
            xml += '</' + prop + '>';
        }
    }
   var xml = xml.replace(/<\/?[0-9]{1,}>/g,'');
   xml = xml.replace(/product_list/g, 'product-list');
   xml = xml.replace(/display_name/g, 'display-name');
   xml = xml.replace(/help_location/g, 'help-location');
   xml = xml.replace(/alt_short_name/g, 'alt-short-name');
   xml = xml.replace(/short_name/g, 'short-name');
   xml = xml.replace(/product_family_list/g, 'product-family-list');
   xml = xml.replace(/product_family/g, 'product-family');
   xml = xml.replace(/documentation_set/g, 'documentation-set');
   return xml
}
