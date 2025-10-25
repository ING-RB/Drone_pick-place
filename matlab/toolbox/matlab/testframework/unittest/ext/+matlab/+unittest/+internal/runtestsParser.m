function [results,suite] = runtestsParser(testsuiteCreatorFcn , varargin)
% This function is undocumented and may change in a future release

% Copyright 2018-2023 The MathWorks, Inc.

import matlab.unittest.plugins.ToStandardOutput;
import matlab.unittest.internal.plugins.PluginProviderData;
import matlab.unittest.Verbosity;

if mod(nargin,2) ~= 0
    testsArg = {};
    args = varargin;
else
    testsArg = varargin(1);
    args = varargin(2:end);
end

parser = inputParser;
parser.KeepUnmatched = true;
nameValueLiaison = locateRuntestsParameters(parser);
nameValueLiaison.addParameter('Debug', false, ...
    @(value)validateTruthyScalar(value), @logical);
nameValueLiaison.addParameter('Strict', false, ...
    @(value)validateTruthyScalar(value), @logical);
nameValueLiaison.addParameter('LoggingLevel', Verbosity.Terse, ...
    @validateVerbosity, @matlab.unittest.Verbosity);
nameValueLiaison.addParameter('OutputDetail', Verbosity.Detailed, ...
    @validateVerbosity, @matlab.unittest.Verbosity);
nameValueLiaison.addParameter('Verbosity', Verbosity.Terse, ...
    @validateVerbosity, @matlab.unittest.Verbosity); % for backward-compatibility
nameValueLiaison.addParameter('UseParallel', false, ...
    @validateTruthyScalar, @logical);
nameValueLiaison.addParameter('OutputStream', ToStandardOutput,...
    @validateOutputStream); % for testing only
nameValueLiaison.addParameter('TestOutputView', 'CommandWindow',...
    @validateTestOutputView);
nameValueLiaison.addParameter('ReportCoverageFor', string.empty, ...
    @(value)validateSources(value));

nameValueLiaison.parse(args{:});
results.Options = nameValueLiaison.Results;
results.Options.GetCoverageResults_ = matlab.unittest.plugins.codecoverage.CoverageResult;

results.Options.TestViewHandler_ = locateTestViewHandlers(nameValueLiaison.Results);

results.TestsuiteInputs = [testsArg,getArgumentsForTestsuite(nameValueLiaison)];
suite = testsuiteCreatorFcn(results.TestsuiteInputs{:});

s = settings;
pluginsFunction = str2func(s.matlab.unittest.DefaultPluginsFcn.ActiveValue);
specifiedOptions = rmfield(results.Options, nameValueLiaison.UsingDefaults);
pluginProviderData = PluginProviderData(specifiedOptions,suite);
results.Plugins = pluginsFunction(pluginProviderData);

end


function args = getArgumentsForTestsuite(nameValueLiaison)
% The following code is required to have 'Recursively' support:
recursivelyParser = inputParser();
recursivelyParser.KeepUnmatched = true;
recursivelyParser.addParameter('IncludeSubfolders',false);
recursivelyParser.addParameter('IncludingSubfolders',false);
recursivelyParser.addParameter("IncludeInnerNamespaces",false);
recursivelyParser.addParameter("IncludingInnerNamespaces",false);
recursivelyParser.addParameter('IncludeSubpackages',false);
recursivelyParser.addParameter('IncludingSubpackages',false);
recursivelyParser.addParameter('Recursively',false);
recursivelyParser.parse(nameValueLiaison.Unmatched);
args = namedargs2cell(recursivelyParser.Unmatched);
results = recursivelyParser.Results;
includeSubfolders = results.IncludeSubfolders || results.IncludingSubfolders;
if ~includeSubfolders && all(ismember({'IncludeSubfolders','IncludingSubfolders'},recursivelyParser.UsingDefaults))
    includeSubfolders = results.Recursively;
end
includeInnerNamespaces = results.IncludeInnerNamespaces || results.IncludingInnerNamespaces || results.IncludeSubpackages || results.IncludingSubpackages;
if ~includeInnerNamespaces && all(ismember(["IncludeSubpackages","IncludingSubpackages","IncludeInnerNamespaces","IncludingInnerNamespaces"], recursivelyParser.UsingDefaults))
    includeInnerNamespaces = results.Recursively;
end
if includeSubfolders
    args = [args,{'IncludeSubfolders',true}];
end
if includeInnerNamespaces
    args = [args,{"IncludeInnerNamespaces",true}];
end
end

function validateVerbosity(verbosity)
validateattributes(verbosity,{'numeric','string','char','matlab.unittest.Verbosity'},{'nonempty','row'});
if ~ischar(verbosity)
    validateattributes(verbosity, {'numeric','string','matlab.unittest.Verbosity'}, {'scalar'});
end
matlab.unittest.Verbosity(verbosity); % Validate that a value is valid
end


function validateTruthyScalar(value)
validateattributes(value, {'numeric','logical'}, {'scalar'});
end


function validateOutputStream(outputStream)
validateattributes(outputStream,{'matlab.unittest.plugins.OutputStream'},{'scalar'});
end

function validateTestOutputView(testViewOption)
mustBeTextScalar(testViewOption);
end

function validateSources(sources)
import matlab.unittest.internal.mustBeTextScalarOrTextArray;
mustBeTextScalarOrTextArray(sources,'sources');
mustBeNonempty(sources);
end

function nameValueLiaison = locateRuntestsParameters(parser)
import matlab.unittest.internal.services.namevalue.locateAdditionalParameters;
nameValueLiaison = locateAdditionalParameters(...
    ?matlab.unittest.internal.services.namevalue.NameValueProviderService, ...
    "matlab.unittest.internal.services.namevalue.runtests", ...
    parser);
end

function testViewHandler = locateTestViewHandlers(options)
liaison = matlab.unittest.internal.services.testoutputviewers.locateTestOutputViewHandlers(options);
testViewHandler = liaison.TestOutputViewHandler;
end

% LocalWords:  Subfolders Subpackages
% LocalWords:  Subfolders Subpackages Truthy codecoverage func namedargs namevalue
