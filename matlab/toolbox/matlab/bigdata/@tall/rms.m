function y = rms(x, varargin)
%RMS    Root mean squared value for tall arrays.
%   Y = RMS(X)
%   Y = RMS(X,DIM)
%   Y = RMS(...,MISSING)
%
%   See also RMS, TALL.

%   Copyright 2017-2021 The MathWorks, Inc.

narginchk(1,3);

% Use the in-memory version to check the arguments
tall.validateSyntax(@rms,[{x},varargin],'DefaultType','double');

if nargin==1
    y = sqrt(mean(x .* conj(x)));
else
    y = sqrt(mean(x .* conj(x), varargin{:}));
end

