function foundFile = edit(fh)
    arguments
        fh (1,1) function_handle
    end

    if nargout
        foundFile = true;
    end

    s = functions(fh);

    if isfile(s.file)
        if s.type == "scopedfunction"
            fullName = append(s.file, filemarker, s.function);
        else
            fullName = s.file;
        end
    else
        % The class field is populated for methods, but it can also be the name of
        % the class that created a function_handle to an ordinary function
        if isfield(s, 'class') && edit(append(s.class, '/', s.function))
            return;
        end
        fullName = s.function;
    end

    if ~edit(fullName)
        if nargout
            foundFile = false;
        else
            error(message('MATLAB:Editor:FunctionHandle', func2str(fh)));
        end
    end
end

%   Copyright 2023 The MathWorks, Inc.
