function success = showPropertyHelp(classname,propname)
%

%   Copyright 2020 The MathWorks, Inc.

    helpview_args = matlab.internal.doc.reference.getHelpviewArgs(classname,propname);
    if ~isempty(helpview_args)
        helpview(helpview_args{:});
        success = 1;
    else
        success = 0;
    end
end

