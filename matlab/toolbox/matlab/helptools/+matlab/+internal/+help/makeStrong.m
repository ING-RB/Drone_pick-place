function name = makeStrong(name, wantHyperlinks, commandIsHelp)
    if wantHyperlinks
        if commandIsHelp
            name = "<strong>" + name + "</strong>";
        else
            name = upper(name);
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.
