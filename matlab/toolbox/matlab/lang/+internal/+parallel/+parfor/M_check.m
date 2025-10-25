function M = M_check(M)
% This function is undocumented and reserved for internal use.  It may be
% removed in a future release.

% Copyright 2007-2021 The MathWorks, Inc.

if (~isnumeric(M) || ~isreal(M) || ~isscalar(M) || M ~= round(M) || M < 0) ...
        && ~isequal(M, 'debug') ...
        && ~isValidParforOptions(M) ...
        && ~isValidEmptyPoolForSerial(M)
    if matlab.internal.parallel.isPCTInstalled && matlab.internal.parallel.isPCTLicensed
        error(message('MATLAB:parfor:InvalidSecondArgument'));
    else
        error(message('MATLAB:parfor:maxWorkers'));
    end
end
end

function tf = isValidParforOptions(M)
tf = isscalar(M) && ...
    (isa(M, 'parallel.parfor.Options') ...
    || isa(M, 'parallel.Cluster') ...
    || isa(M, 'parallel.Pool'));
end

function tf = isValidEmptyPoolForSerial(M)
tf = isempty(M) && isa(M, 'parallel.Pool');
end