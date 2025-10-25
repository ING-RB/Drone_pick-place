function [sortedk,ind] = topkrows(this,k,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:topkrows:InvalidAbsRealType'));
    end
end

% Lexicographic sort of complex data
if nargout < 2
    newdata = topkrows(this.data,k,varargin{:},'ComparisonMethod','real');
else
    [newdata,ind] = topkrows(this.data,k,varargin{:},'ComparisonMethod','real');
end

sortedk = this;
sortedk.data = newdata;
