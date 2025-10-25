function cellchar = validateCellStringInput(rhs,propertyname, isDatastore)
%

%   Copyright 2018-2020 The MathWorks, Inc.

    if (isnumeric(rhs) || isdatetime(rhs))
        cellchar = rhs;
        return
    end

    if ~exist('isDatastore','var')
        isDatastore = false;
    end

    if (isDatastore && iscellofstrings(rhs))
        error(message('MATLAB:datastoreio:tabulartextdatastore:invalidStrOrCellStr',propertyname));
    end

    if iscellofstrings(rhs)
        error(message('MATLAB:textio:textio:InvalidStringOrCellStringProperty',propertyname));
    end

    cellchar = convertStringsToChars(rhs);

end

function x = iscellofstrings(rhs)
    x = ~(iscellstr(rhs) || ischar(rhs) || isstring(rhs));
end
