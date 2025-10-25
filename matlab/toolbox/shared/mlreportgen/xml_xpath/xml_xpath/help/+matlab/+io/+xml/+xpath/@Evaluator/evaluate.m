%evaluate Evaluate an XPath expression
%   result = evaluate(this,xpExpr,xmlFilePath) evaluates the
%   specified XPath expression in the context of the specified XML file and
%   returns the result as an object whose type is determined by the 
%   XPath expression. For example, an expression that selects a string
%   returns a string.
%
%   By default the parser used to parse the specified XML file does not
%   support parsing a document that specifies a document type definition
%   (DTD). If the document to be parsed specifies a DTD, the parser throws
%   an error and exits. This is done to prevent infecting the local system
%   with a virus posing as a DTD. 
%
%   result = evaluate(this,xpExpr,xmlFilePath,allowDoctype) evaluates the
%   specified XPath expression in the context of the specified XML file.
%   The allowDoctype argument specifies whether the XML file can contain a
%   document type definition (DTD). If the specified file contains a DTD
%   and allowDoctype is false, an error is thrown. If allowDoctype is true,
%   an error is not thrown if the XML file contains a DTD. However, it is
%   recommended that this option be enabled only for trusted sources.
%
%   result = evaluate(this,xpExpr,xmlFilePath,resType)
%   evaluates the specified XPath expression in the context of the
%   specified XML file and returns the result as the specified result type.
%
%   result = evaluate(this,xpExpr,xmlFilePath,resType,allowDoctype)
%   evaluates the specified XPath expression in the context of the
%   specified XML file and returns the result as the specified result type.
%   The allowDoctype argument specifies whether the XML file can contain a
%   document type definition (DTD). If the specified file contains a DTD
%   and allowDoctype is false, an error is thrown. If allowDoctype is true,
%   an error is not thrown if the XML file contains a DTD. However, it is
%   recommended that this option be enabled only for trusted sources.
%
%   result = evaluate(this,xpExpr,ctxNode) evaluates an XPath
%   expression in the context of the specified parsed document node and
%   returns the result as an object whose type is determined by the 
%   XPath expression. For example, an expression that selects a string
%   returns a string.
%
%   result = evaluate(this,xpExpr,ctxNode,resType)
%   evaluates an XPath expression in the context of  the specified parsed
%   document node. Returns the result as the specified result type.
%
%   To evaluate an XPath expression in the context of a file stored at a
%   remote location, the file must be specified as a parsed document node.
%   See the matlab.io.xml.dom.Parser.parseFile documentation for
%   details on parsing remote files.
%
%   Note: An XPath expression evaluator stores results of all XPath
%   evaluations it performs throughout its lifetime. To avoid running out
%   of memory, do not use the same evaluator for large amounts of
%   evaluations, and clear matlab.io.xml.xpath.Evaluator instances once
%   they are no longer needed.
%
%   INPUT ARGUMENT TYPES
%
%   Evaluator evaluate methods accept the following inputs:
%
%   Name         Description                 Type
%   -----------------------------------------------------------------------
%   this         XPath expression evaluator  matlab.io.xml.xpath.Evaluator
%   xpExpr       XPath 1.0 expression        - string scalar
%                                            - character vector
%                                            - matlab.io.xml.xpath.CompiledExpression
%   ctxNode      Evaluation context node     matlab.io.xml.dom.Node
%   resType      Evaluation result type      matlab.io.xml.xpath.EvalResultType
%   allowDoctype Document type definition    boolean
%                (DTD) permissions
%
%   OUTPUT ARGUMENT TYPES
%
%   If a resType input is not specified, the evaluate output is a string
%   scalar. If a resType input is specified, the evaluate output  depends
%   on the specified result type enumeration:
%
%   Result Type	             Data Type
%   -----------------------------------------------------------------------
%   EvalResultType.Boolean   logical
%   EvalResultType.Number    double
%   EvalResultType.Node      matlab.io.xml.dom.Node
%   EvalResultType.NodeSet   matlab.io.xml.dom.Node vector
%   EvalResultType.String    string scalar
%
%    See also matlab.io.xml.xpath.ResultType,
%    matlab.io.xml.xpath.Evaluator.ResolvePrefixes

%    Copyright 2020-2023 MathWorks, Inc.
%    Built-in function.

