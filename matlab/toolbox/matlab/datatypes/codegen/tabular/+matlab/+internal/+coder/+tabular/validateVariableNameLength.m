function tooLong = validateVariableNameLength(names,tooLongErrorID) %#codegen
%VALIDATEVARIABLENAMELENGTH checks that variable names do not exceed namelengthmax.
%   This function takes a cell array of variable names and errors if any are longer
%   than namelengthmax.

%   Copyright 2018-2024 The MathWorks, Inc.

coder.extrinsic('namelengthmax', 'strlength');

nameLengths = coder.const(strlength(coder.const(names)));

% Error if longer than namelengthmax
nameLengthMax = coder.const(namelengthmax);
tooLong = (nameLengths > nameLengthMax);
namesCellstr = coder.const(cellstr(names)); % guard against scalar string
tooLong1 = coder.const(find(tooLong, 1)); % subscript namesnamesCellstr with first index, but return full logical vector
coder.internal.errorIf( nargout == 0 && coder.const(any(tooLong)), ...
    tooLongErrorID,namesCellstr{tooLong1},nameLengths(tooLong1),nameLengthMax);

% Error if 0-length or NaN
coder.internal.assert( all(nameLengths>0), 'MATLAB:table:ZeroLengthVarname');