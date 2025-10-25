function mustBeTextScalar(value,varargin)
% This function is undocumented and may change in a future release.

%    mustBeTextScalar(value) validates that the value provided is a
%    character vector or a non-missing string scalar.
%
%    mustBeTextScalar(...,nameOfValue) includes the nameOfValue
%    in any error thrown.

% Copyright 2017-2022 The MathWorks, Inc.
validateattributes(value,{'char','string'},{'scalartext'},'',varargin{:});
end