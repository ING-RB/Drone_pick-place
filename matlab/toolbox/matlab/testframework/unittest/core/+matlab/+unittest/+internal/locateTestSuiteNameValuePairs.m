function nameValueLiaison = locateTestSuiteNameValuePairs(parser, namedargs)
%

% Copyright 2021-2024 The MathWorks, Inc.

arguments
    parser;
    namedargs.OnlySelectors (1,1) logical = false;
    namedargs.InformalSuite (1,1) logical = false;
end

import matlab.unittest.internal.services.namevalue.locateAdditionalParameters;

namespaces = "matlab.unittest.internal.services.namevalue.suiteselection";
if ~namedargs.OnlySelectors
    namespaces = [namespaces, "matlab.unittest.internal.services.namevalue.suitecreation"];
end

if namedargs.InformalSuite
    namespaces = [namespaces, "matlab.unittest.internal.services.namevalue.suitecreation.informalsuite"];
end

nameValueLiaison = locateAdditionalParameters(...
    ?matlab.unittest.internal.services.namevalue.NameValueProviderService, ...
    namespaces, parser);
end

% LocalWords:  namedargs namevalue suiteselection suitecreation
