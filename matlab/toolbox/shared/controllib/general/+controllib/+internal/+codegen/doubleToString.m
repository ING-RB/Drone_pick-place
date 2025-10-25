function str = doubleToString(value,charwidth) 
%DOUBLETOSTRING Convert double to a string
%
%    str = doubleToString(value,[charwidth])
%
%    Convert a double value to a string using formatting.
%
%    Inputs:
%      value     - 2D double matrix to convert
%      charwidth - integer specifying the line width to use when formatting
%                  the string, if omitted the default value of 76 is used,
%                  charwidth must be a finite integer greater than 10
% 
%    Outputs:
%      str - formatted string of the passed value
%

%Note:
%
%    This function is intended as a temporary workaround to
%    Simulink.saveVars that as of R2012b only writes values directly to a
%    file.
%
 
% Author(s): A. Stothert 06-Feb-2012
% Copyright 2012 The MathWorks, Inc.

%Process input arguments
if ~(isa(value,'double') && ismatrix(value))
    error(message('SLControllib:general:errDoubleToString_NonDoubleValue'));
end
if nargin < 2, 
    charwidth = 76; 
elseif ~(isnumeric(charwidth) && isscalar(charwidth) && ...
        isfinite(charwidth) && ~isnan(charwidth) && charwidth > 10 && ...
        (mod(charwidth,1) == 0))
    error(message('SLControllib:general:errCellToString_BadCharWidth','doubleToString'));
end

if numel(value) == 1
    %Scalar case
    str = lScalarToString(value);
else
    %Matrix case
    str = mat2str(value);
    if length(str) > charwidth
        str = controllib.internal.codegen.matrixToString(value,charwidth,@lScalarToString);
        str = sprintf('[%s]',str);
    end
end
end

function str = lScalarToString(value)
%Helper function to convert a scalar double to a string

str = mat2str(value,16);
end