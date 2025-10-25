function [b,i] = mink(a,k,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc. 

if ~isnumeric(k)
    error(message('MATLAB:topk:InvalidK'));
end

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:mink:InvalidAbsRealType'));
    end
end

if ~isempty(varargin) && ~isnumeric(varargin{1})
    error(message('MATLAB:topk:notPosInt'));
end

if ~a.isOrdinal
    error(message('MATLAB:categorical:NotOrdinal'));
end

acodes = a.codes;
acodes(acodes == categorical.undefCode) = invalidCode(acodes); % Set invalidCode

[bcodes,i] = mink(acodes,k,varargin{:});
bcodes(bcodes == invalidCode(bcodes)) = a.undefCode; % set invalidCode back to <undefined> code

b = a; % preserve subclass
b.codes = bcodes;
