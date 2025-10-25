function y = quantile(x,p,varargin)
% Syntax:
%     Q = quantile(A,p)
%     Q = quantile(A,n)
%     Q = quantile(___,vecdim)
%     Q = quantile(___,Method=method)
%
% For more information, see documentation

%   Copyright 1993-2024 The MathWorks, Inc. 

if ~(isreal(p) && (isnumeric(p) || islogical(p)) && isvector(p) && ~isempty(p))
    error(message('MATLAB:quantile:BadProbs'));
else
    if ~isfloat(p)
        p = double(p);
    end
    if all(isfinite(p)) && isscalar(p) && (p == round(p)) && (p > 1) % 1 means 100%, not 1 quantile
        p = (1:p) / (p+1);
    elseif any(p < 0 | p > 1)
        error(message('MATLAB:quantile:BadProbs'));
    end
end

y = prctile(x,100.*p,varargin{:});
