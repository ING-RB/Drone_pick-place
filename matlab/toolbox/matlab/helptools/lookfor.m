function out = lookfor(args)
    % Lookfor keywords in reference page or help text
    arguments (Repeating)
        args {mustBeTextScalar}
    end
    args = string(args);

    lp = matlab.internal.help.Lookfor(args);

    if lp.topic == ""
        error(message("MATLAB:lookfor:noKeyword"));
    end

    lp.collect = nargout>0;

    if ~lp.doLookfor && ~lp.collect
        disp(getString(message("MATLAB:lookfor:notFound", lp.topic)))
    elseif lp.collect
        out = lp.getCollection;
    elseif lp.justH1
        fprintf(newline);
    end
end

%   Copyright 1984-2023 The MathWorks, Inc.

