function outS = summary(X,varargin)
% Syntax:
%   SUMMARY(X)
%   SUMMARY(X,VECDIM)
%   SUMMARY(___,Statistics=stats)
%
% For more information, see tabular/summary, categorical/summary, and documentation

%   Copyright 2024 The MathWorks, Inc.

isDimSet = false;

if nargin > 1
    dim = varargin{1};
    if matlab.internal.math.checkInputName(dim,'all')
        dim = 1:ndims(X);
        isDimSet = true;
    elseif ~ischar(dim) && ~(isstring(dim) && isscalar(dim))
        if isempty(dim) || ~isvector(dim) || ~isnumeric(dim) || ~isreal(dim) || ~allfinite(dim) || any(fix(dim) ~= dim) || any(dim < 1) 
            error(message('MATLAB:getdimarg:invalidDim'));
        end
        if ~isscalar(dim) && ~all(diff(sort(dim)))
            error(message('MATLAB:getdimarg:vecDimsMustBeUniquePositiveIntegers'));
        end
        isDimSet = true;
    end
    indStart = 1 + isDimSet;
    Xistabular = false;
    [isStatisticsSet,specifiedStats] = ...
        matlab.internal.math.parseSummaryNVArgs(varargin(indStart:end),Xistabular,islogical(X),X);
else
    isStatisticsSet = false;
    specifiedStats = {};
end

if ~isDimSet
    dim = matlab.internal.math.firstNonSingletonDim(X);
end

[stats,statFields,fcnHandles] = matlab.internal.math.createStatsList(X,dim,isStatisticsSet,specifiedStats);
S = matlab.internal.math.datasummary(X,stats,statFields,fcnHandles,dim);

% Display or return
if nargout > 0
    outS = S;
else
    printArraySummary(S,X,dim,inputname(1));
end
end

%--------------------------------------------------------------------------
function printArraySummary(S,x,dim,dataName)
import matlab.internal.display.lineSpacingCharacter

if matlab.internal.display.isDesktopInUse % the environment supports boldface
    varnameFmt = '<strong>%s</strong>';
else
    % The display environment may not support boldface
    varnameFmt = '%s';
end

% Display size and type
fprintf(lineSpacingCharacter);
if ~isempty(dataName)
    fprintf([varnameFmt ': '],dataName);
end
sz = S.Size;

% matlab.internal.display.getDimensionSpecifier returns the small 'x'
% character for size, e.g., 'mxn'
szStr = [sprintf('%d',sz(1)) sprintf([matlab.internal.display.getDimensionSpecifier,'%d'],sz(2:end))];

if iscellstr(x) %#ok<ISCLSTR>
    typeLabel = getString(message('MATLAB:summary:CellStr'));
elseif issparse(x)
    typeLabel = getString(message('MATLAB:summary:Sparse',S.Type));
else
    typeLabel = S.Type;
end
fprintf('%s %s\n',szStr,typeLabel);
S = rmfield(S,{'Size';'Type'});

if isfield(S,'TimeZone')
    if ~isempty(S.TimeZone)
        fprintf('\tTimeZone: %s\n',S.TimeZone);
    end
    S = rmfield(S,'TimeZone');
end

% Display stats
labels = fieldnames(S);
if ~isempty(labels)
    dim = sort(dim);
    dimIsAll = isequal(dim,1:ndims(x));
    matlab.internal.math.displaySummaryStats(S,x,sz,labels,varnameFmt,dim,dimIsAll);
end
end