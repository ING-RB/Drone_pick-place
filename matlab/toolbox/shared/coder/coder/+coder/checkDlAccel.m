function [result, errorList, report] = checkDlAccel
%CODER.CHECKDLACCEL Verify the GPU code generation environment for DLAccel
%

%   Copyright 2017-2018 The MathWorks, Inc.
%   
    try
        [result, errorList, report] = coder.internal.checkDlAccelPrivate();
    catch e
        throw(e);
    end

end


