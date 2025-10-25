function y = detrend(x,varargin)
%   Syntax:
%      D = detrend(A)
%      D = detrend(A,n)
%      D = detrend(A,n,bp)
%      D = detrend(___,nanflag)
%      D = detrend(___,Name,Value)
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

% Parse inputs
[x,polyDeg,bp,s,continuity,sizeX,N,isrowx,isNDx,omitnan,...
    xIsTabular,dataVars,replace,permuteRow] = parseInputs(x, varargin{:});

notUniquePoly = false;

if xIsTabular
    [y,notUniquePoly] = detrendTable(x,omitnan,polyDeg,bp,s,continuity,dataVars,replace,notUniquePoly);
else
    [y,notUniquePoly] = detrendArray(x,omitnan,polyDeg,bp,s,sizeX,isrowx,isNDx,continuity,N,permuteRow,notUniquePoly);
end

if notUniquePoly
    warning(message('MATLAB:detrend:PolyNotUnique'));
end

end

function [y,notUniquePoly] = detrendArray(x,omitnan,polyDeg,bp,s,sizeX,isrowx,isNDx,continuity,N,permuteRow,notUniquePoly)
if omitnan && anynan(x)
    nanMask = isnan(x);
    y= NaN(size(x),"like",x);
    if iscolumn(x)
        bpNoNans = trimBp(bp,s(~nanMask));
        [y(~nanMask),notUniquePoly] = detrendInternal(x(~nanMask),polyDeg,bpNoNans,s(~nanMask),continuity,nnz(~nanMask),notUniquePoly);
    else
        columnHasNan = any(nanMask,1);
        if any(~columnHasNan)
            bp = trimBp(bp,s);
            [y(:,~columnHasNan),notUniquePoly] = detrendInternal(x(:,~columnHasNan),polyDeg,bp,s,continuity,N,notUniquePoly);
        end
        columnInd = find(columnHasNan);
        for ii = columnInd
            bpNoNans = trimBp(bp,s(~nanMask(:,ii)));
            [y(~nanMask(:,ii),ii),notUniquePoly] = detrendInternal(x(~nanMask(:,ii),ii),...
                polyDeg,bpNoNans,s(~nanMask(:,ii)),continuity,nnz(~nanMask(:,ii)),notUniquePoly);
        end
    end
else
    bp = trimBp(bp,s);
    [y,notUniquePoly] = detrendInternal(x,polyDeg,bp,s,continuity,N,notUniquePoly);
end

if isrowx && permuteRow
    y = y.';
elseif isNDx
    y = reshape(y,sizeX);
end
end

function [y,notUniquePoly] = detrendTable(x,omitnan,polyDeg,bp,s,continuity,dataVars,replace,notUniquePoly)
tempTable = x(:,dataVars);
for i = 1:numel(dataVars)
    tempVar = x.(dataVars(i));
    permuteRow = false; % Don't convert a row vector into a column vector for table variables
    [tempVar,sizeX,N,isrowx,isNDx] = reshapeInput(tempVar,permuteRow);
    [tempTable.(i),notUniquePoly] = detrendArray(tempVar,omitnan,polyDeg,bp,s,sizeX,isrowx,isNDx,continuity,N,permuteRow,notUniquePoly);
end

if replace
    x(:,dataVars) = tempTable;
    y = x;
else
    y = matlab.internal.math.appendDataVariables(x,tempTable,"detrended");
end
end

function [y,notUniquePoly] = detrendInternal(x,polyDeg,bp,s,continuity,N,notUniquePoly)

lbp = numel(bp);

% Apply method
if continuity
    if polyDeg == 0
        if isempty(bp)
            y = x - mean(x,1);
        else
            % Continuous constant subtracts the mean of the first segment
            [~,begSeg] = min(abs(s-bp(1)));
            if lbp == 1
                endSeg = numel(s);
            else
                [~,endSeg] = min(abs(s - bp(2)));
            end
            segMean = mean(x(begSeg:endSeg,:),1);
            y = x - segMean;
        end
    else
        % Continuous, piecewise polynomial trend

        % Normalize to avoid numerical issues
        if isempty(s)
            a = s;
            scaleS = s;
        else
            scaleS = s(end);
            if scaleS == 0
                a = s;
            else
                a = s./scaleS;
            end
        end

        % Build regressor
        b = a - (bp./scaleS)';
        b = max(b,0);
        W = b(:).^(polyDeg:-1:1);
        W = [reshape(W,N,[]), ones(N,1)];
        x1 = full(x);
        W = cast(W,"like",x1);

        % Solve least squares problem p = W\x1
        [p, rankW] = matlab.internal.math.leastSquaresFit(W,x1);

        if size(W,1) < size(W,2) || rankW < size(W,2)
            notUniquePoly=true;
        end
        % Remove best fit
        y = x - cast(W*p,"like",x);
    end
else
    y = zeros(size(x),"like",x);
    segments = sum(s >= bp',2);
    x1 = full(x);
    for k = 1:lbp

        segidx = segments == k;

        if polyDeg == 0 || nnz(segidx) == 1
            % Remove mean from each segment
            y(segidx,:) = x(segidx,:) - mean(x(segidx,:),1);
        else
            % Normalize before fitting polynomial
            a = s(segidx);
            [std_a, mean_a] = std(a);
            a = (a - mean_a)./std_a;

            % Construct the Vandermonde matrix
            V = [a.^(polyDeg:-1:1), ones(nnz(segidx),1)];
            V = cast(V,"like",x1);

            % Solve least squares problem tr = V\x1
            [tr, rankV] = matlab.internal.math.leastSquaresFit(V,x1(segidx,:));

            if size(V,1) < size(V,2) || rankV < size(V,2)
                notUniquePoly = true;
            end

            % Remove best fit
            y(segidx,:) = x(segidx,:) - V*tr;
        end
    end
end
end
%--------------------------------------------------------------------------
function [x,polyDeg,bp,s,continuity,sizeX,N,isrowx,isNDx,omitNan,...
    xIsTabular,dataVars,replace,permuteRow] = parseInputs(x, varargin)
% Parse inputs

xIsTabular = istabular(x);

if ~isfloat(x) && ~xIsTabular
    error(message('MATLAB:detrend:InvalidFirstInput'));
end

permuteRow = true; %Convert row vector to column vector if it's not the content of a table variable
[x,sizeX,N,isrowx,isNDx] = reshapeInput(x,permuteRow);

% Set default values
bp = [];
continuity = true;
omitNan = false;
dataVars = 1:width(x);
replace = true;
polyDeg = 1;
if isa(x, 'timetable')
    s = matlab.internal.math.checkSamplePoints(x.Properties.RowTimes,x,false,true,1);
else
    s = [];
end

if nargin > 1
    % varargin default
    polyDeg = varargin{1};
    indStart = 2;

    % parse degree n
    if ~isscalar(polyDeg) && ~ischar(polyDeg)
        error(message('MATLAB:detrend:InvalidTrendInputType'));
    elseif ischar(polyDeg) || isstring(polyDeg)
        if strncmpi(polyDeg,'constant',max(4,strlength(polyDeg)))
            polyDeg = 0;
        elseif strncmpi(polyDeg,'linear',max(1,strlength(polyDeg)))
            polyDeg = 1;
        else
            % Assume NV pair
            polyDeg = 1;
            indStart = 1;
        end
    elseif ~islogical(polyDeg) && (~isnumeric(polyDeg) || ~isreal(polyDeg) || polyDeg < 0 || mod(polyDeg,1) ~= 0)
        error(message('MATLAB:detrend:InvalidTrendInputType'));
    else
        polyDeg = double(polyDeg);
    end

    % Parse break points bp
    if nargin > 2 && ~(ischar(varargin{indStart}) || isstring(varargin{indStart}))
        bp = varargin{indStart};
        indStart = indStart+1;
    end

    if indStart<nargin && (ischar(varargin{indStart}) || isstring(varargin{indStart}))
        if any(matlab.internal.math.checkInputName(varargin{indStart},{'omitnan','omitmissing'},1))
            omitNan = true;
            indStart = indStart+1;
        elseif any(matlab.internal.math.checkInputName(varargin{indStart},{'includenan','includemissing'},1))
            indStart = indStart+1;
        end
    end

    % Parse name-value pairs
    [continuity,s,dataVars,replace] = parseNV(indStart,nargin,continuity,s,x,xIsTabular,dataVars,replace,varargin{:});
end

if xIsTabular
    for i = 1:numel(dataVars)
        tvar=x.(dataVars(i));
        %isfloat(doubleGpuArray) returns true, so use isobject to exclude gpuArray and friends
        if ~isfloat(tvar) || isobject(tvar) && ismethod(tvar,'detrend')
            error(message('MATLAB:detrend:InvalidInputVar'));
        end
    end
end

% Check bp now that we have non-default s
if isempty(bp)
    if isnumeric(s) && (isnumeric(bp) || islogical(bp)) ||...
            isdatetime(s) && (isnumeric(bp) || islogical(bp) || isdatetime(bp)) ||...
            isduration(s) && (isnumeric(bp) || islogical(bp) || isduration(bp))
        %For datetime and duration s, isnumeric(bp) is needed to make sure empty
        %bp, like [] or double.empty, works with no issues
        bp=[];
    else
        error(message('MATLAB:detrend:BreakpointsInvalid'));
    end
else
    if (isnumeric(bp) && ~isreal(bp)) || ...
            ~isvector(bp) ||issparse(bp) || ...
            ~(islogical(bp) || (isnumeric(bp) && isnumeric(s))) && ...
            ~isequal(class(bp), class(s))
        %Last logical says: if bp and s are of different datatypes, then either bp is logical or bp and s are of different kinds of numeric datatypes

        error(message('MATLAB:detrend:BreakpointsInvalid'));
    end
end

% Always use a double abscissa s and center
minS = min(s);
if isempty(s)
    s = (0:N-1).'; % Default [1 2 3 ... n]
    if isnumeric(bp)
        % Ignores logical bps because they don't need to be corrected
        % Ignores datetime/duration bps because s can only be an empty of
        % those times if the data is also empty
        bp = double(bp) - 1;
    end
elseif isduration(s)
    s = milliseconds(s - minS);
    if ~islogical(bp)
        bp = milliseconds(bp - minS);
    end
elseif isdatetime(s)
    if ~islogical(bp)
        if isempty(bp)
            bp = 0;
        else
            bp = milliseconds(bp - minS);
        end
    end
    s = milliseconds(s - minS);
else
    s = double(s - minS);
    if ~islogical(bp)
        bp = double(bp - minS);
    end
end

if islogical(bp)
    s_numel = numel(s);
    if numel(bp)>s_numel
        bp = bp(1:s_numel);
    end
    bp = s(bp);
end
end
%--------------------------------------------------------------------------
function [continuity,s,dataVars,replace] = parseNV(indStart,num,continuity,s,x,xIsTabular,dataVars,replace,varargin)
spvar = [];
dim = 1; %always 1 for detrend

% Parse name-value pairs
if rem(num-indStart,2) ~= 0
    error(message('MATLAB:detrend:KeyWithoutValue'));
end
for j = indStart:2:numel(varargin)
    name = varargin{j};
    if matlab.internal.math.checkInputName(name,{'Continuous'},4)
        continuity = varargin{j+1};
        continuity=matlab.internal.datatypes.validateLogical(continuity,'Continuous');
    elseif matlab.internal.math.checkInputName(name,{'SamplePoints'},1)
        s=varargin{j+1};
        if xIsTabular
            if istimetable(x)
                error(message("MATLAB:samplePoints:SamplePointsTimeTable"));
            end
        else
            if (~isfloat(s) && ~isduration(s) && ~isdatetime(s))
                error(message('MATLAB:samplePoints:SamplePointsInvalidDatatype'));
            end
        end
        [s,spvar] = matlab.internal.math.checkSamplePoints(s,x,xIsTabular,false,dim);
    elseif matlab.internal.math.checkInputName(name,{'ReplaceValues'}, 1)
        if xIsTabular
            replace = matlab.internal.datatypes.validateLogical(varargin{j+1},'ReplaceValues');
        else
            error(message('MATLAB:detrend:ReplaceValuesArray'))
        end
    elseif matlab.internal.math.checkInputName(name,{'DataVariables'},1)
        if xIsTabular
            dataVars = matlab.internal.math.checkDataVariables(x, varargin{j+1}, 'detrend');
        else
            error(message('MATLAB:detrend:DataVariablesArray'));
        end
    else
        error(message('MATLAB:detrend:ParseFlags'));
    end
end

if ~isempty(spvar)
    dataVars(dataVars == spvar) = []; % remove sample points var from data vars
end

end

function [x,sizeX,N,isrowx,isNDx] = reshapeInput(x,permuteRow)
sizeX = size(x);
isrowx = isrow(x);
isNDx = ~ismatrix(x); % this means x is multidimensional

if ~istabular(x)
    if isrowx && permuteRow
        x = x(:);   % If a row, turn into column vector, but no need for this if a table variable is 1 x N
    elseif isNDx
        x = reshape(x,sizeX(1),[]); % If x is multidimensional, turn into a matrix
    end
end
N = size(x,1);
end

%--------------------------------------------------------------------------
function bp = trimBp(bp,s)
% Include bookend around break points
if ~isempty(s)
    bp = unique([s(1); bp(:)]); %first samplepoint must be the first breakpoint and bp is sorted via unique
    if numel(bp) > 1
        bp = bp(bp >= s(1) & bp < s(end)); %only bp within the range of s are used
    end
else
    bp = [];
end
end

