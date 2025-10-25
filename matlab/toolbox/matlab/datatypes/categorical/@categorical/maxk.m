function [b,i] = maxk(a,k,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc. 

if ~isnumeric(k)
    error(message('MATLAB:topk:InvalidK'));
end

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:maxk:InvalidAbsRealType'));
    end
end

if ~isempty(varargin) && ~isnumeric(varargin{1})
    error(message('MATLAB:topk:notPosInt'));
end

if ~a.isOrdinal
    error(message('MATLAB:categorical:NotOrdinal'));
end

acodes = a.codes;
[bcodes,i] = maxk(acodes,k,varargin{:});

b = a; % preserve subclass
b.codes = bcodes;
