function nameValueLiaison = testSuiteInputParser(varargin)
% This function is undocumented and may change in a future release.

% Copyright 2018-2021 The MathWorks, Inc.

import matlab.unittest.internal.validateParameter;
import matlab.unittest.internal.locateTestSuiteNameValuePairs;

parser = matlab.unittest.internal.strictInputParser;
parser.addOptional('Modifier', []);
parser.addParameter('ParameterProperty',[]);
parser.addParameter('ParameterName',[]);
parser.addParameter('Name',[]);
parser.addParameter('BaseFolder',[]);
parser.addParameter('Tag',[]);
parser.addParameter('ProcedureName',[]);
parser.addParameter('Superclass',[]);
parser.addParameter('ExternalParameters',...
    matlab.unittest.parameters.Parameter.empty(1,0),...
    @validateParameter);

nameValueLiaison = locateTestSuiteNameValuePairs(parser, varargin{:});
end
