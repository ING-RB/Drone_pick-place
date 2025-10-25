function [D,isDimSet,dim,omitnan,omitzero,isWeighted,w] = parseErrorMetricsInput(forMape,F,A,varargin)
% parseErrorMetricsInput Helper for error metrics functions
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   MAPE(F,A)                        MAPE(F,A,dim)
%   MAPE(F,A,nanflag)                MAPE(F,A,dim,nanflag)
%   MAPE(F,A,zeroflag)               MAPE(F,A,dim,zeroflag)
%   MAPE(F,A,nanflag,zeroflag)       MAPE(F,A,dim,nanflag,zeroflag)
%   MAPE(F,A,zeroflag,nanflag)       MAPE(F,A,dim,zeroflag,nanflag)
%   MAPE(F,A,"Weight",W)             MAPE(F,A,dim,"Weight",W)
%   MAPE(F,A,nanflag,"Weight",W)     MAPE(F,A,dim,nanflag,"Weight",W)
%   MAPE(F,A,zeroflag,"Weight",W)    MAPE(F,A,dim,zeroflag,"Weight",W)
%   MAPE(F,A,zeroflag,nanflag,"Weight",W)
%   MAPE(F,A,nanflag,zeroflag,"Weight",W)
%   MAPE(F,A,dim,zeroflag,nanflag,"Weight",W)
%   MAPE(F,A,dim,nanflag,zeroflag,"Weight",W)
%
% RMSE has the same syntaxes as MAPE, except that it does not have the
% zeroflag.

% Copyright 2022-2023 The MathWorks, Inc.

if ~isfloat(F)
    error(message('MATLAB:errormetrics:InvalidData'));
end
if ~isfloat(A)
    error(message('MATLAB:errormetrics:InvalidData'));
end
% Computing the difference checks that F and A have compatible sizes
D = A-F;

% Parse dim
isDimSet = false;
if nargin > 3
    dim = varargin{1};
    isDimSet = ((~ischar(dim) && ~(isstring(dim) && isscalar(dim))) || ...
        matlab.internal.math.checkInputName(dim,'all'));
end
if ~isDimSet
    dim = matlab.internal.math.firstNonSingletonDim(D);
end

% Parse flags and weight
omitnan = false;
omitzero = false;
isWeighted = false;
w = [];

if nargin == 3 || (nargin == 4 && isDimSet)
    % Syntax: mape(F,A) or mape(F,A,dim)
    return
end

indStart = 1 + isDimSet;
flag = varargin{indStart};
[isFlag,omitnan,omitzero,s] = checkFlag(flag,forMape);

if nargin == 4
    if isFlag
        % Syntax: mape(F,A,flag)
        return
    else
        unknownFlagError(forMape);
    end
end

if nargin > 5 || ~isDimSet || ~isFlag
    if forMape && isFlag
        % mape can have two flags
        indStart = indStart + 1;
        flag = varargin{indStart};
        [isFlag,omitnan2,omitzero2,s2] = checkFlag(flag,forMape);
        if ( any(s(1:4)) && any(s2(1:4)) ) || ( any(s(5:6)) && any(s2(5:6)) )
            % Either both flags were nanflags or both were zeroflags
            error(message('MATLAB:errormetrics:UnknownFlagMAPE'));
        end
        omitnan = omitnan || omitnan2;
        omitzero = omitzero || omitzero2;
    end
    indStart = indStart + isFlag;
    num = numel(varargin);

    % Parse any NV args
    if rem(num-indStart,2) == 0
        if matlab.internal.math.checkInputName(varargin{end},'Weights')
            error(message('MATLAB:errormetrics:KeyWithoutValue'));
        elseif matlab.internal.math.checkInputName(varargin{indStart},'Weights')
            error(message('MATLAB:errormetrics:InvalidPositionWeight'));
        else
            unknownFlagError(forMape);
        end
    else
        % When mape has two flags and no NV args, indStart = num + 1
        for j = indStart:2:num
            name = varargin{j};
            if ~matlab.internal.math.checkInputName(name,'Weights')
                if isWeighted
                    error(message('MATLAB:errormetrics:InvalidPositionWeight'));
                else
                    error(message('MATLAB:errormetrics:ParseNames'));
                end
            else
                w = varargin{j+1};
                if ~isreal(w) || ~isfloat(w) || ...
                   (omitnan && any(w < 0,'all')) || (~omitnan && ~all(w >= 0,'all'))
                    error(message('MATLAB:errormetrics:InvalidWeight'));
                end
                if isDimSet && (isempty(dim) || ~isscalar(dim) || ischar(dim) || isstring(dim))
                    error(message('MATLAB:errormetrics:WeightWithVecdim'));
                end
                if isequal(size(D),size(w))
                    reshapeWeights = false;
                elseif isvector(w)
                    if numel(w) ~= size(D,dim)
                        error(message('MATLAB:errormetrics:InvalidSizeVectorWeight'));              
                    end
                    reshapeWeights = true;
                else
                    if ~(isequal(size(A),size(w)) || isequal(size(F),size(w)))
                        error(message('MATLAB:errormetrics:InvalidSizeWeight'));
                    end
                    reshapeWeights = false;
                end
                isWeighted = true;
            end
        end
        if isWeighted
            if reshapeWeights
                % Reshape w to be applied in the direction dim
                sz = size(D);
                sz(end+1:dim) = 1;
                wresize = ones(size(sz));
                wresize(dim) = sz(dim);
                w = reshape(w, wresize);
                if omitnan || omitzero
                    % Repeat w, such that the new w has the same size as D
                    wtile = sz;
                    wtile(dim) = 1;
                    w = repmat(w, wtile);
                end
            end
            if omitnan
                w(isnan(D)) = NaN;
            end
        end
    end
end
end

%% Helper functions
function [isFlag,omitnan,omitzero,s] = checkFlag(flag,forMape)
if forMape
    validFlags = {'omitnan', 'includenan', 'omitmissing', 'includemissing', 'omitzero', 'includezero'};
else
    validFlags = {'omitnan', 'includenan', 'omitmissing', 'includemissing'};
end
s = matlab.internal.math.checkInputName(flag, validFlags);
if forMape && sum(s) > 1
   % Catch ambiguities, e.g. mape(F,A,'omit')
   error(message('MATLAB:errormetrics:UnknownFlagMAPE'));
end
isFlag = any(s);
omitnan = s(1) || s(3);
omitzero = forMape && s(5);
end

function unknownFlagError(forMape)
if forMape
    error(message('MATLAB:errormetrics:UnknownFlagMAPE'));
else
    error(message('MATLAB:errormetrics:UnknownFlag'));
end
end