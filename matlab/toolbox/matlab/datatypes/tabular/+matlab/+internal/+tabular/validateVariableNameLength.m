function tooLong = validateVariableNameLength(names,tooLongErrorID,doError)
%VALIDATEVARIABLENAMELENGTH checks that variable names do not exceed namelengthmax.
%   This function takes a cell array of variable names and errors if any are longer
%   than namelengthmax.

%   Copyright 2018-2024 The MathWorks, Inc.

arguments
    names
    tooLongErrorID
    doError logical = false;
end

nameLengths = strlength(names);
tooLong = (nameLengths > namelengthmax);
if any(tooLong)
    if (nargout == 0 || doError)
        varidx = find(tooLong,1);
        error(message(tooLongErrorID,names{varidx},nameLengths(varidx),namelengthmax));
    end
elseif all(nameLengths > 0)
    % good names
else % 0-length or NaN. All callers need to error for this case, so this branch should always error.
    error(message('MATLAB:table:ZeroLengthVarname')) % Not hit by metaDim
end
