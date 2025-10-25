function m = median(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isValidDimArg

omitMissing = false;
hasWeights = false;
if nargin == 1 % median(a)
    haveDim = false;
else
    if ~isa(a,"datetime")
        m = matlab.internal.datatypes.fevalFunctionOnPath("median",a,varargin{:});
        return;
    end
    [haveDim,allFlag] = isValidDimArg(varargin{1}); % positive scalar or 'all'
    if haveDim
        dim = varargin{1};
        varargin(1) = [];
        if allFlag
            a = reshape(a,[],1);
            dim = 1;
        end
    end

    idx = 1;
    while idx <= numel(varargin)
        if numel(varargin) > 1 && idx < numel(varargin) && isScalarText(varargin{idx}) && strncmpi(varargin{idx},'Weights',max(1,strlength(varargin{idx})))
            hasWeights = true;
            weights = varargin{idx+1}; % To be validated after determining omitMissing flag.
            varargin(idx:idx+1) = [];
        elseif ~isempty(varargin) && isScalarText(varargin{idx}) && strncmpi(varargin{idx},'Weights',max(1,strlength(varargin{idx})))
            error(message("MATLAB:weights:ArgNameValueMismatch"))
        else
            idx = idx + 1;
        end
    end

    if haveDim
        if nargin == 2 || isempty(varargin) % median(a,dim), median(a,dim,Weights=w),
            % omitMissing = false;
        else % median(a,dim,missing),  median(a,dim,missing,Weights=w)
            if strncmpi(varargin{end},'Weights',max(1,strlength(varargin{end})))
                error(message("MATLAB:weights:ArgNameValueMismatch"))
            elseif isscalar(varargin)
                errID = "MATLAB:datetime:UnknownNaNFlag"; % dim already found, don't suggest 'all'
                omitMissing = validateDatafunOptions(varargin{1},errID);
            else
                error(message("MATLAB:datetime:UnknownNaNFlag"))
            end
        end
    elseif isscalar(varargin) && isScalarText(varargin{1}) % might be median(a,missing) median(a,missing,Weights=w)
        errID = "MATLAB:datetime:UnknownNaNFlagAllFlag";
        omitMissing = validateDatafunOptions(varargin{1},errID);
    elseif hasWeights && isempty(varargin)
        % median(a,Weights=w)
    else
        error(message('MATLAB:datetime:InvalidVecDim'));
    end
end

aData = a.data;
szIn = size(aData);
if ~haveDim
    dim = find(szIn~=1,1);
    if isempty(dim), dim = 1; end
end

if hasWeights
    weights = matlab.internal.datetime.validateWeights(weights,a,omitMissing,haveDim,allFlag,dim);
    if omitMissing
        weights(ismissing(a)) = NaN;
    end
end

if isempty(aData)
    if ~haveDim && isequal(aData,[])
        % The output size for [] is a special case when DIM is not given.
        mData = NaN;
        szOut = [1 1];
    else
        % Set output size to 1 along the working dimension.
        szOut = szIn;
        szOut(dim) = 1;
        mData = NaN(szOut);
    end
elseif all(dim > ndims(aData))
    szOut = szIn;
    mData = aData;
else
    if isscalar(dim) && dim == 2 && ismatrix(aData) && ~hasWeights % special case for rowwise on a matrix (no trailing dims)
        aData = sort(aData,dim,'ComparisonMethod','real');
        % Set output size to 1 along the working dimension.
        szOut = szIn;
        szOut(dim) = 1;
        mData = NaN(szOut); % the low order part will be created if/when needed
        if omitMissing
            % NaN sorts to the end, ignore them for 'omitnan' by treating each column's
            % "length" as its number of non-NaN elements. Except: if every element in the
            % column is NaN, set its "length" to 1, so that the last (n-th) element is NaN
            % when we go to check it.
            n = size(aData,dim) - matlab.internal.math.countnan(aData,dim);
            n(n == 0) = 1;
        else % 'includenan'
            % NaN sorts to the end, so if there are any NaNs in a column, the last element
            % of the sorted column will certainly be NaN. For 'includenan', get the column
            % length so that we can check that last (n-th) element.
            n = repmat(size(aData,dim),szOut);
        end
        half = floor(n/2);
        [nrow,~] = size(aData);
        for i = 1:nrow
            if ~isnan(aData(i,n(i))) % if last element is NaN, leave median as NaN
                mData(i) = aData(i,half(i)+1);
                if 2*half(i) == n(i)
                    mData(i) = datetimeMidpoint(aData(i,half(i)),mData(i));
                end
            end
        end
    else
        [aData,szOut,perm] = permuteWorkingDims(aData,dim);
        if hasWeights
            weights = permuteWorkingDims(weights,dim);
            mData = weightedmedian(aData,omitMissing,weights);
        else
    
            mData = NaN([1 prod(szOut)]);
            
            aData = sort(aData,1,'ComparisonMethod','real');
            
            if omitMissing
                % NaN sorts to the end, ignore them for 'omitnan' by treating each column's
                % "length" as its number of non-NaN elements. Except: if every element in the
                % column is NaN, set its "length" to 1, so that the last (n-th) element is NaN
                % when we go to check it.
                n = size(aData,1) - matlab.internal.math.countnan(aData,1);
                n(n == 0) = 1;
            else % 'includenan'
                % NaN sorts to the end, so if there are any NaNs in a column, the last element
                % of the sorted column will certainly be NaN. For 'includenan', get the column
                % length so that we can check that last (n-th) element.
                n = repmat(size(aData,1),szOut(perm));
            end
            half = floor(n/2);
            
            [~,ncol] = size(aData);
            for j = 1:ncol
                if ~isnan(aData(n(j),j)) % if last element is NaN, leave median as NaN
                    mData(j) = aData(half(j)+1,j);
                    if 2*half(j) == n(j)
                        mData(j) = datetimeMidpoint(aData(half(j),j),mData(j));
                    end
                end
            end
        end
    end
end
m = a;
m.data = reshape(mData,szOut);

%============================

function cdata = datetimeMidpoint(adata,bdata)
import matlab.internal.datetime.datetimeAdd
import matlab.internal.datetime.datetimeSubtract
% Find the midpoint between two datetimes.
cdata = datetimeAdd(adata,datetimeSubtract(bdata,adata,true)/2);
k = (sign(adata) ~= sign(bdata)) | isinf(adata) | isinf(bdata);
cdata(k) = datetimeAdd(adata(k),bdata(k))/2;

%============================

function wM = weightedmedian(x,omitnan,w)
xIsColumn = iscolumn(x);
if xIsColumn
    wM = vectorWeightedMedian(x,w,omitnan);
else
    wM = zeros(1,size(x,2), 'like', x([]));
    for ii = 1:size(x,2)
        wM(ii) = vectorWeightedMedian(x(:,ii),w(:,ii),omitnan);
    end
end

%============================

function wM = vectorWeightedMedian(x,w,omitnan)
if omitnan
    % All NaNs in x are in w
    x = x(~isnan(w));
    w = w(~isnan(w));
end

if any(w == 0)
    x(w == 0) = [];
    w(w == 0) = [];
end

if isempty(x) || any(isinf(w))
    % w can't contain Infs since it's not clear what that should mean
    wM = NaN('like',x);
    return;
end

[sX,I] = sort(x);

if isnan(sX(end))
    wM = NaN('like',x);
    return;
end

sW = w(I);
% scale the weight vector to avoid overflow
% use nextpow2 to avoid precision loss from division
sW = sW./2^(nextpow2(max(sW))-1);
csw = cumsum(sW);
cswr = cumsum(sW,'reverse');
y = find(csw >= 0.5*csw(end),1);
yr = find(cswr >= 0.5*csw(end),1,'last');

if y == yr
    wM = sX(y);
else
    wM = datetimeMidpoint(sX(y),sX(yr));
end
