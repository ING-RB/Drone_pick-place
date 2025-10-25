function getdisp(obj)
%

%   Copyright 2017-2020 The MathWorks, Inc.

try % display the builtin get's output
    if isempty(obj)
        return
    end

    out = get(obj);

    orderedOut = orderfields(out);
    disp(orderedOut);
catch exception
    if ~all(isvalid(obj))
        % if given at least one invalid object, bail out now with error.
        error(message('MATLAB:timer:invalid'));
    else
        throw(exception);
    end
end
