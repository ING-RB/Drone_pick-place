function [sortedk,ind] = mink(this,k,varargin)
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

% Lexicographic sort of complex data
if nargout < 2
    newdata = mink(this.data,k,varargin{:},'ComparisonMethod','real');
else
    [newdata,ind] = mink(this.data,k,varargin{:},'ComparisonMethod','real');
end

sortedk = this;
sortedk.data = newdata;
