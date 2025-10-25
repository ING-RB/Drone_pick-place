function initSupportRequest
%

% Copyright 2024 The MathWorks, Inc.
    if feature("webui") && usejava("swing")
        com.mathworks.webintegration.supportrequest.SubmitSupportRequestDialog.invoke;
    else
        matlab.internal.supportrequest.openWebSupportRequest;
    end
end