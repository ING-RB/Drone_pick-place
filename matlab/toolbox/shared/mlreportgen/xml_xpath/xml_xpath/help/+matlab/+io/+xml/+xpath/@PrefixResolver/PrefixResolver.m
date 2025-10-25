%matlab.io.xml.xpath.PrefixResolver Resolve namespace prefixes
%   This is an abstract base class for objects that resolve namespace
%   prefixes that occur in XPath expressions. Classes derived from this
%   class must provide implementations for its methods. You cannot
%   create instances of this class. You must subclass this class if
%   you want to create a prefix resolver. 
%
%   PrefixResolver methods:
%      getNamespaceForPrefix - Get the namespace that defines a prefix
%      getURL                - Get the base URL for namespace prefixes
%
%   See also matlab.io.xml.xpath.Evaluator.ResolvePrefixes

%   Copyright 2020 MathWorks, Inc.
%   Built-in function.