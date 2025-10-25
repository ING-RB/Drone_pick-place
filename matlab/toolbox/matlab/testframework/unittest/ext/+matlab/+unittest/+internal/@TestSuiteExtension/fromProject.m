function suite = fromProject(project, varargin)
% fromProject - Create a suite from all tests in a project that are labeled "Test"
%
%   SUITE = matlab.unittest.TestSuite.fromProject(PROJECT) creates a TestSuite 
%   array from all test files contained in PROJECT that are labeled "Test", and 
%   returns that array in SUITE. PROJECT is either a loaded project object or
%   the root folder of project. The method is not recursive. It returns only 
%   those tests in the project specified.
%
%   SUITE = matlab.unittest.TestSuite.fromProject(PROJECT, 'IncludingReferencedProjects', true)
%   creates a TestSuite array from all test files contained in PROJECT, and all 
%   referenced projects, that are labeled "Test".
%
%   SUITE = matlab.unittest.TestSuite.fromProject(PROJECT, ATTRIBUTE_1, CONSTRAINT_1, ...)
%   creates a TestSuite array from all test files contained in PROJECT that are 
%   labeled "Test" and that satisfy the specified conditions. Specify any of the 
%   following attributes:
%
%       * Name              - Name of the suite element
%       * ProcedureName     - Name of the test procedure in the test
%       * Superclass        - Name of a class that the test class derives
%                             from
%       * BaseFolder        - Name of the folder that holds the file
%                             defining the test class or function.
%       * ParameterProperty - Name of a property that defines a
%                             Parameter used by the suite element
%       * ParameterName     - Name of a Parameter used by the suite element
%       * Tag               - Name of a tag defined on the suite element. 
%
%   The value of each attribute is specified as a string array, character vector, 
%   or cell array of character vectors. For all attributes except Superclass, the 
%   value can contain wildcard characters "*" (matches any number of characters, 
%   including zero) and "?" (matches exactly one character). A test is included 
%   in the suite only if it satisfies the criteria specified by all attributes. 
%   For each attribute, the test element must satisfy at least one of the options
%   specified for that attribute.
%
%   SUITE = matlab.unittest.TestSuite.fromProject(PROJECT, SELECTOR) creates a 
%   TestSuite array from all of the Test methods of all concrete TestCase 
%   classes contained in PROJECT that are labeled "Test" and that satisfy the 
%   SELECTOR.
%
%   SUITE = matlab.unittest.TestSuite.fromProject(__, 'ExternalParameters', PARAM)
%   allows the suite to use PARAM, an array of matlab.unittest.parameters.Parameter
%   instances. The framework uses the external parameters in place of
%   corresponding parameters that are defined within parameterized tests.
%
%   Examples:
%       import matlab.unittest.TestSuite;
%
%       project = openProject('C:/projects/project1/');
%
%       suite = TestSuite.fromProject(project);
%       result = run(suite)
%
%       % Include only select project folders
%       suite = TestSuite.fromProject(project, 'BaseFolder', 'TestFeature1');
%       result = run(suite)
%
%   See also: TestRunner, TestSuite.fromFolder, TestSuite.fromNamespace, matlab.unittest.selectors
% 

% Copyright 2018-2023 The MathWorks, Inc.

import matlab.unittest.internal.fromProjectCore_;
import matlab.unittest.internal.resolveAliasedLogicalParameters;

narginchk(1, Inf);
parser = matlab.unittest.internal.testSuiteInputParser;
parser.Parser.KeepUnmatched = true;
parser.addParameter('IncludingReferencedProjects', false, @(x)validateIncludingRef(x,'IncludingReferencedProjects'));
parser.addParameter('IncludeReferencedProjects', false, @(x)validateIncludingRef(x,'IncludeReferencedProjects'));
parser.parse(varargin{:});
results = parser.Results;
explicitlySpecifiedResults = rmfield(results, parser.UsingDefaults);
includeReferencedProjects = resolveAliasedLogicalParameters(explicitlySpecifiedResults, ...
    ["IncludingReferencedProjects", "IncludeReferencedProjects"]);
modifier = parsingResultsToModifier(parser);
externalParameters = results.ExternalParameters;
args = namedargs2cell(parser.Unmatched);
suite = fromProjectCore_(project, modifier, externalParameters, includeReferencedProjects, args{:});
end

function validateIncludingRef(value, varname)
validateattributes(value, {'logical'}, {'scalar'}, '', varname);
end
          
function modifier = parsingResultsToModifier(parser)
import matlab.unittest.internal.selectors.getSuiteModifier;

results = rmfield(parser.Results, parser.UsingDefaults);
modifier = getSuiteModifier(results);
end

% LocalWords:  namedargs varname
