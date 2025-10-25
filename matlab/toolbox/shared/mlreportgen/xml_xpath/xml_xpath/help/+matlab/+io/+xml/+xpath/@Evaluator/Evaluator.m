%matlab.io.xml.xpath.Evaluator Defines an XPath expression evaluator
%    evaluator = Evaluator() creates an XPath evaluator.
%
%    Evaluator methods:
%       compileExpression - Compile an XPath expression
%       evaluate          - Evaluate an XPath expression  
%
%    Evaluator properties:
%       PrefixResolver      - Custom prefix resolver
%       ResolvePrefixes     - Whether to resolve namespace prefixes
%
%    Note: An XPath expression evaluator stores results of all XPath
%    evaluations it performs throughout its lifetime. To avoid running out
%    of memory, do not use the same evaluator for large amounts of
%    evaluations, and clear matlab.io.xml.xpath.Evaluator instances once
%    they are no longer needed.
%
%    Evaluator supports these standard XPath functions in XPath expressions:
%
%    concat
%    contains
%    id
%    lang
%    namespace-uri
%    normalize-space
%    starts-with
%    string
%    substring
%    substring-after
%    substring-before
%    translate
%
%    See https://www.w3.org/TR/xpath-functions-31/ for a definition and
%    usage of these functions.

%    Copyright 2020-2023 MathWorks, Inc.
%    Built-in class

%{
properties
     %PrefixResolver Custom prefix resolver
     %    This property is empty by default. To provide a custom namespace
     %    prefix resolver, create a class derived from 
     %    matlab.io.xml.xpath.PrefixResolver and set this property to an
     %    instance of the derived class.
     %
     %    See also matlab.io.xml.xpath.PrefixResolver
     PrefixResolver;

     %ResolvePrefixes Whether to resolve namespace prefixes
     %    If this property is true (the default), the evaluator attempts 
     %    to resolve namespace prefixes that occur in the XPath expression
     %    to be evaluated. You can specify a prefix resolver, using
     %    the evaluator's setPrefixResolver method. If you specify a 
     %    resolver and this property is true, the evaluator uses the
     %    specified resolver to resolve prefixes. If you do not specify
     %    a resolver and this property is true, the evaluator uses the
     %    evaluation context node's parent document to resolve prefixes. 
     ResolvePrefixes;
end
%}