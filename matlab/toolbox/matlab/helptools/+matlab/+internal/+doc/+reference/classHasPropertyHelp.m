function has_help = classHasPropertyHelp(classname)
%

%   Copyright 2020 The MathWorks, Inc.

    has_help = ~isempty(matlab.internal.doc.reference.getHelpviewArgs(classname));
end

