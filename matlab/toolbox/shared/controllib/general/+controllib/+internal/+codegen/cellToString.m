function str = cellToString(value,charwidth)
%CELLTOSTRING Convert cell array to a string
%
%    str = cellToString(value,[charwidth])
%
%    Convert a cell array of doubles or strings to a string using
%    formatting.
%
%    Inputs:
%      value     - 2D cell array of doubles or strings to convert
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
if ~(isa(value,'cell') && ismatrix(value))
    error(message('SLControllib:general:errCellToString_NonCellValue'));
end
if nargin < 2,
    charwidth = 76;
elseif ~(isnumeric(charwidth) && isscalar(charwidth) && ...
        isfinite(charwidth) && ~isnan(charwidth) && charwidth > 10 && ...
        (mod(charwidth,1) == 0))
    error(message('SLControllib:general:errCellToString_BadCharWidth','cellToString'));
end

%Handle scalar case
nV = numel(value);
if nV == 0
    %Empty case
    sz = size(value);
    if all(sz==0)
        str = '{}';
    else
        str = sprintf('cell(%s)',mat2str(sz));
    end
elseif nV == 1
    %Scalar case
    str = lScalarToString(value,charwidth);
    str = sprintf('{%s}',str);
else
    %Matrix case
    str = controllib.internal.codegen.matrixToString(value,charwidth,@(x) lScalarToString(x,charwidth));
    str = sprintf('{%s}',str);
end
end

function str = lScalarToString(value,charwidth)
%Helper function to convert an element of a cell array to a string

if iscell(value)
    if iscell(value{1})
        %Recurse and construct string for the cell element
        str = controllib.internal.codegen.cellToString(value{1},charwidth);
    else
        value = value{1};
        if ischar(value)
            str = sprintf('''%s''',value);
        elseif isa(value,'double')
            %Construct string for a double
            str = controllib.internal.codegen.doubleToString(value,charwidth);
        else
            error(message('SLControllib:general:UnexpectedError'));
        end
    end
end
end