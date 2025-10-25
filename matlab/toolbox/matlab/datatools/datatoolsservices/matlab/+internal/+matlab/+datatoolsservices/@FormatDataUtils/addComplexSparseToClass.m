% Add in complex/sparse to the class name for classes which are not real or
% sparse.

% Copyright 2015-2023 The MathWorks, Inc.

function clazz = addComplexSparseToClass(clazz, isReal, isSparse, useParens)
    arguments
        clazz
        isReal
        isSparse
        useParens = false
    end
    %TODO: no easy to way to check for class 'global'
    origClazz = clazz;
    if ~isReal
        if useParens
            clazz = [clazz ' (complex)'];
        else
            clazz = ['complex ' clazz];
        end
    end
    if isSparse
        if useParens
            if ~isReal
                clazz = [ origClazz ' (sparse complex)'];
            else
                clazz = [clazz ' (sparse)'];
            end
        else
            clazz = ['sparse ' clazz];
        end
    end
end
