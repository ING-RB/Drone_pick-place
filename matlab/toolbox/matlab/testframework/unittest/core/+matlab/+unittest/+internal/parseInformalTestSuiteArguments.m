function [tests, options] = parseInformalTestSuiteArguments(varargin)
%   parseInformalTestSuiteArguments is undocumented function
%   Gets the list of tests and constructs informal test suite creation 
%   options
%

%   Copyright 2024 The MathWorks, Inc.

import matlab.unittest.internal.locateTestSuiteNameValuePairs;
import matlab.unittest.internal.resolveAliasedLogicalParameters;
import matlab.unittest.internal.services.informalsuite.InformalSuiteCreationOptions;
import matlab.unittest.internal.selectors.getSuiteModifier;

if mod(nargin,2) == 0
    tests = pwd;
    args = varargin;
else
    tests = varargin{1};
    args = varargin(2:end);
end

parser = inputParser;
parser.addParameter('BaseFolder',[]);
parser.addParameter('IncludeSubfolders', false, @validateTruthyScalar);
parser.addParameter('IncludeInnerNamespaces', false, @validateTruthyScalar);
parser.addParameter('IncludeReferencedProjects', false, @validateTruthyScalar);
parser.addParameter('IncludingSubfolders', false, @validateTruthyScalar); % supported alias
parser.addParameter('IncludingInnerNamespaces', false, @validateTruthyScalar); % supported alias
parser.addParameter('IncludeSubpackages', false, @validateTruthyScalar); % supported alias
parser.addParameter('IncludingSubpackages', false, @validateTruthyScalar); % supported alias
parser.addParameter('IncludingReferencedProjects', false, @validateTruthyScalar); % supported alias
parser.addParameter('InvalidFileFoundAction', 'warn', @validateBehaviorString);
parser.addParameter('Name',[]);
parser.addParameter('ParameterName',[]);
parser.addParameter('ParameterProperty',[]);
parser.addParameter('Tag',[]);
parser.addParameter('ProcedureName',[]);
parser.addParameter('Superclass',[]);
nameValueLiaison = locateTestSuiteNameValuePairs(parser, "InformalSuite", 1);

nameValueLiaison.parse(args{:});
results = nameValueLiaison.Results;
explicitlySpecifiedResults = rmfield(results, nameValueLiaison.UsingDefaults);

includeSubfolders = resolveAliasedLogicalParameters(explicitlySpecifiedResults, ["IncludeSubfolders","IncludingSubfolders"]);
includeInnerNamespaces = resolveAliasedLogicalParameters(explicitlySpecifiedResults, ["IncludeInnerNamespaces","IncludingInnerNamespaces","IncludeSubpackages","IncludingSubpackages"]);
includeReferencedProjects = resolveAliasedLogicalParameters(explicitlySpecifiedResults, ["IncludeReferencedProjects","IncludingReferencedProjects"]);

externalParams = matlab.unittest.parameters.Parameter.empty;
if isfield(results, 'ExternalParameters')
    externalParams = results.ExternalParameters;
end

options = InformalSuiteCreationOptions(Modifier = getSuiteModifier(explicitlySpecifiedResults), ...
    IncludeSubfolders = includeSubfolders, ...
    IncludeInnerNamespaces = includeInnerNamespaces, ...
    IncludeReferencedProjects = includeReferencedProjects, ...
    InvalidFileFoundAction = results.InvalidFileFoundAction, ...
    ExternalParameters=externalParams);
end

function validateTruthyScalar(value)
validateattributes(value, {'numeric','logical'}, {'scalar'});
end

function validateBehaviorString(value)
mustBeMember(value,["error","warn"]);
end