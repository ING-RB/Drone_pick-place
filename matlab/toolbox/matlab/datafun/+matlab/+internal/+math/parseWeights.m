function [w,isWeighted] =parseWeights(x,dim,isDimSet, omitnan,nvp)
if ~isfloat(x)
    error(message('MATLAB:weights:InvalidData'));
end

len = numel(nvp);
if ~matlab.internal.math.checkInputName(nvp{1},'Weights')
     error(message('MATLAB:median:unknownOption'))
elseif rem(len,2) ~= 0
    error(message('MATLAB:weights:ArgNameValueMismatch'))
end

for ii = 1:2:len
    if ii>1 && ~matlab.internal.math.checkInputName(nvp{ii},'Weights')
        error(message('MATLAB:weights:UnknownParameter'));
    end
    w = nvp{ii+1};
    if ~isreal(w) || ~isfloat(w) || ...
            (omitnan && any(w < 0,'all')) || (~omitnan && ~all(w >= 0,'all'))
        error(message('MATLAB:weights:InvalidWeight'));
    end
    if isDimSet && (isempty(dim) || ~isscalar(dim) || ischar(dim) || isstring(dim))
        error(message('MATLAB:weights:WeightWithVecdim'));
    end
    if isequal(size(x),size(w))
        reshapeWeights = false;
    elseif isvector(w)
        if (numel(w) ~= size(x,dim))
            error(message('MATLAB:weights:InvalidSizeWeight'));
        end
        reshapeWeights = true;
    else
        error(message('MATLAB:weights:InvalidSizeWeight'));
    end
    isWeighted = true;
end

if reshapeWeights
    % Reshape w to be applied in the direction dim
    sz = size(x);
    sz(end+1:dim) = 1;
    wresize = ones(size(sz));
    wresize(dim) = sz(dim);
    w = reshape(w, wresize);
    if omitnan
        % Repeat w, such that the new w has the same size as x
        wtile = sz;
        wtile(dim) = 1;
        w = repmat(w, wtile);
    end
end
if omitnan
    w(isnan(x)) = NaN;
end
end