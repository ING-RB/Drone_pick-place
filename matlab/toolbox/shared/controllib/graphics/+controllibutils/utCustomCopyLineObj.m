function NewHLine = utCustomCopyLineObj(HLine,Parent)
%   utCustomCopyLineObj - Internal helper function for copying lines with
%   there callback

%  Copyright 2014 The MathWorks, Inc.

    NewHLine = handle(copyobj(HLine,Parent));
    NewHLine.ButtonDownFcn = HLine.ButtonDownFcn;
end