function [a,i,j] = unique(a,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

narginchk(1,Inf);

if ~iscategorical(a)
    % catch the case where a varargin input is categorical and is dispatched here.
    error(message('MATLAB:categorical:setmembership:UnknownInput'));
end

acodes = a.codes;

% Rely on built-in's NaN handling if input contains any <undefined> elements
acodes = categorical.castCodesForBuiltins(acodes);

try
    % Call unique with appropriate output args for optimal performance
    if nargout == 1
        acodes = unique(acodes,varargin{:});
    elseif nargout == 2
        [acodes,i] = unique(acodes,varargin{:});
    else
        [acodes,i,j] = unique(acodes,varargin{:});
    end
catch ME
    throw(ME);
end

if isfloat(acodes)
    % Cast back to integer codes, including NaN -> <undefined>
    acodes = categorical.castCodes(acodes,length(a.categoryNames));
end
a.codes = acodes;

