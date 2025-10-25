%evaluate Evaluate an XPath expression
%    result = evaluate(thisDoc,xpath,contextNode,namespaceResolver, ...
%    resultType) evaluates the specified XPath expression and returns a
%    result of the specified type. This method accepts the following
%    input arguments:
%
%        * thisDoc: a namespace-aware instance of the
%          matlab.io.xml.dom.Document class. If parsed from a file, the
%          parser must have been configured to recognize namespaces.
%         
%        * xpath: a string or character array that specifies an XPath
%          expression that does not include predicates and has only one
%          "//" operator. The expression should use qualified names to 
%          specify elements that have qualified names.
%
%        * contextNode: an Element node in this document to be used as the
%          context for evaluating the XPath expression. Only this
%          element and its descendants are matched against the specified
%          XPath expression.
%
%        * namespaceResolver: an instance of
%          matlab.io.xml.dom.XPathNSResolver used to resolve undeclared
%          qualified name prefixes.
%
%        * resultType: a double value that specifies a valid result type. 
%          The matlab.io.xml.dom.XPathResult class provides static methods
%          that generate valid result types, for example, 
%          ORDERED_NODE_SNAPSHOT_TYPE. Use one of these methods to 
%          generate this argument.
%
%    This method returns a ResultType object containing the nodes that
%    match the XPath expression.
%
%    result = evaluate(thisDoc,xpath,contextNode,resultType) uses the
%    specified Element node as the context for matching elements against
%    the xpath expression. The parser used to create this document from a
%    file must have been configured to ignore namespace declarations. The
%    XPath expression must use only unqualified names.
%
%    result = evaluate(thisDoc,xpath,resultType) uses this document's
%    root element as the context for matching elements against the
%    xpath expression. The parser used to create this document from a 
%    file must have been configured to ignore namespace declarations.
%    The XPath expression must use only unqualified names.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    wordFile = 'magic-square.docx';
%    unzip(wordFile);
%    xmlFile = 'word/document.xml';
%    p = Parser;
%    p.Configuration.Namespaces = true;
%    d = parseFile(p,xmlFile);
%    e = getDocumentElement(d);
%    resolver = createNSResolver(d,e);
%    resType = matlab.io.xml.dom.XPathResult.ORDERED_NODE_SNAPSHOT_TYPE;
%    nodeSnapshot = evaluate(d,'//w:p',e,resolver,resType);
%    nNodes = getSnapshotLength(nodeSnapshot);
%    for i = 1:nNodes
%        snapshotItem(nodeSnapshot,i-1);
%        node = getNodeValue(nodeSnapshot);
%    end
%
%    See also matlab.io.xml.dom.XPathResult,
%    matlab.io.xml.dom.XPathNSResolver,
%    matlab.io.xml.dom.Document.createNSResolver,
%    matlab.io.xml.dom.Document.ParserConfiguration.Namespaces

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.