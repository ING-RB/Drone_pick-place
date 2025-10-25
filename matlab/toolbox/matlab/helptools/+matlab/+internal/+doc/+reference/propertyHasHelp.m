function has_help = propertyHasHelp(classname,propname)
%

%   Copyright 2020 The MathWorks, Inc.

    has_help = ~isempty(matlab.internal.doc.reference.getHelpviewArgs(classname,propname));
end

