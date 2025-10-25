function validateSupportedWriteCellType(C)
%VALIDATESUPPORTEDWRITECELLTYPE Errors if the given cell array C is not a
% cell type supported for writing with WRITECELL.

%   Copyright 2019-2022 The MathWorks, Inc.

    import matlab.io.internal.interface.isSupportedWriteMatrixType

    if iscell(C) && ~iscellstr(C) %#ok<ISCLSTR>
        for elem = C(:)'
            A = elem{:};
            if iscell(A)
                throwAsCaller(MException(message("MATLAB:table:write:UnsupportedNestedCell")));
            elseif ~isSupportedWriteMatrixType(A)
                throwAsCaller(MException(message("MATLAB:table:write:UnsupportedTypeInCell", class(A))));
            end
        end
    end

end
