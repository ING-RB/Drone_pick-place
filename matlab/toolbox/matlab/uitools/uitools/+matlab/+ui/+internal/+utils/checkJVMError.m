function checkJVMError
% This function is for internal MathWorks use only.

% This is a special version of usejava for internal purposes. This does an
% additional decaf check to enable workflows in decaf mode (dialogs) using
% web figures that are otherwise disabled in nojvm. g2447933

%   Copyright 2021 The MathWorks, Inc.
persistent isdecaf;
if isempty(isdecaf)
    isdecaf = matlab.ui.internal.dialog.DialogUtils.checkDecaf;
end

if ~isdecaf && ~usejava('jvm')
    error(message('MATLAB:HandleGraphics:noJVM'));
end

end
