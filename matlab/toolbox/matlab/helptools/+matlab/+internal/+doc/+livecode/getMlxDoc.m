function html = getMlxDoc(filePath)
%

%   Copyright 2020-2021 The MathWorks, Inc.

    xmlString = matlab.internal.doc.getDocumentationXML(filePath);
    if xmlString ~= ""
        % Read the xml string directly into an XML model object
        dom = getDocXml(xmlString);
        xsltfile = fullfile(fileparts(mfilename('fullpath')),'private','mlxdoc.xsl');
        
        transformer = matlab.io.xml.transform.Transformer;
        transformer.OutputEncoding = "UTF-8";
        sourceDoc = matlab.io.xml.transform.SourceDocument(dom);
        
        result = matlab.io.xml.transform.ResultString;
        transform(transformer, sourceDoc, xsltfile, result);
        html = char(result.String);
    else
        html = '';
    end
end

function dom = getDocXml(xmlString)
    dom = parseString(matlab.io.xml.dom.Parser, xmlString);

    % Add some information about global file locations to the dom.
    includesDir = matlab.internal.doc.url.MwDocPage;
    includesDir.DocLocation = "INSTALLED";
    includesDir.ContentType = "Standalone";
    includesDir.RelativePath = "customdoc/includes";
    appendDomElement(dom, 'includes', char(includesDir));
    
    searchPage = matlab.internal.doc.url.DocSearchPage;
    searchPage.DocLocation = "INSTALLED";
    searchUrl = searchPage.getUrl;
    searchUrl.Query = [];
    appendDomElement(dom, 'searchpage', char(searchUrl));
    landingPage = matlab.internal.doc.url.MwDocPage;
    landingPage.DocLocation = "INSTALLED";
    appendDomElement(dom, 'landingpage', char(landingPage));
end

function appendDomElement(dom, eltName, eltValue)
    newElt = dom.createElement(eltName);
    newText = dom.createTextNode(eltValue);
    newElt.appendChild(newText);
    dom.getDocumentElement.appendChild(newElt);
end
