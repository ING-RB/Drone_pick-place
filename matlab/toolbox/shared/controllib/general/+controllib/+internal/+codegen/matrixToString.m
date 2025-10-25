function str = matrixToString(value,charwidth,fcnScalar) 
%

%MATRIXTOSTRING
%
%  str = matrixToString(value,charwidth,fcnScalar)
%
%  A utility function used by doubleToString and cellToString to format a
%  string value.
%
%  Inputs:
%     value     - a double or cell array to convert to a string
%     charwidth - an integer specifying the line width to use when
%                 formatting the string
%     fcnScalar - a function handle used to convert scalar cell elements to
%                 strings
%
 
% Author(s): A. Stothert 06-Feb-2012
% Copyright 2012 The MathWorks, Inc.

%Useful constants
rowSep  = ';';
colSep  = ',';
sz      = size(value);

if any(sz==1)
    %Vector case
    if isrow(value)
        sep = colSep;
    else
        sep = rowSep;
    end
    str = lVectorToString(value,sep,charwidth,fcnScalar);
else
    %Matrix case
    str        = '';
    strNewLine = sprintf(' ...\n');
    for ctR = 1:sz(1)
        %Create string for row
        strRow = lVectorToString(value(ctR,:),colSep,charwidth,fcnScalar);
        
        %Always put new row on a new line
        if ctR < sz(1)
            str = sprintf('%s%s%s%s', str, strRow, rowSep, strNewLine);
        else
            str = sprintf('%s%s', str, strRow);
        end
    end
end

end

function str = lVectorToString(value,sep,charwidth,fcnScalar)
%Helper function to convert a vector into a string

nV         = numel(value);
str        = '';
strLine    = '';
strNewLine = sprintf(' ...\n');
for ct=1:nV-1
    val = value(ct);
    strLine = sprintf('%s%s%s ',strLine,fcnScalar(val),sep);
    if length(strLine) >= charwidth - length(strNewLine)
        %Reached wrap limit, create a new line
        strLine = sprintf('%s%s',strLine,strNewLine);
        str = sprintf('%s%s',str,strLine);
        strLine = '';
    elseif ct == nV-1
        %Got to last element without needing a new line
        str = sprintf('%s%s',str,strLine);
    end
end
%Add last element
str = sprintf('%s%s', str, fcnScalar(value(nV)));
end