%

%   Copyright 2023 The MathWorks, Inc.

function varargout = generateHTMLReport(resultName, expectedKey, options)
arguments
    resultName (1,1) string
    expectedKey (1,1) string
    options.Folder string = string.empty()
end

nargoutchk(0,1);

if ~evalin('base', sprintf('exist(''%s'',''var'');', resultName))
    throwAsCaller(MException(message('MATLAB:coverage:result:GenHTMLReportVariableMustExist', resultName)));
end
resObj = evalin('base', resultName);

if ~isa(resObj,'matlab.coverage.Result')
    throwAsCaller(MException(message('MATLAB:coverage:result:GenHTMLReportMustBeACovResult', resultName)));
end

if isempty(resObj)
    throwAsCaller(MException(message('MATLAB:coverage:result:GenHTMLReportStaleCovResults', resultName)));
end

actualKey = matlab.coverage.internal.computeResultDigest(resObj);

if ~strcmp(actualKey, expectedKey)
    throwAsCaller(MException(message('MATLAB:coverage:result:GenHTMLReportStaleCovResults', resultName)));
end

args{1} = resObj(:);
if ~isempty(options.Folder) && (strlength(options.Folder) > 0)
    args{2} = options.Folder;
end

[varargout{1:nargout}] = generateHTMLReport(args{:});

% LocalWords:  GenHTMLReportMustBeACovResult
