function platformInfo = getPlatformInfo()
    % GETPLATFORMINFO Returns Platform arch string to be shared with Add-On
    % Explorer. The following table lists the string value returned.
    % ----------------------------------------
    % | computer('arch')  | output            |
    % |_______________________________________|
    % | maci64            | Mac64             |
    % | glnxa64           | Lnx64             |
    % | win64             | Win64             |
    % | win32             | Win32             |
    % | someotherplatform | someotherplatform |
    % |_______________________________________|

    % Copyright: 2021 The MathWorks, Inc.

    if strcmpi(matlab.internal.addons.util.explorer.computerArch, 'maci64')
        platformInfo = 'Mac64';
    elseif strcmpi(matlab.internal.addons.util.explorer.computerArch, 'glnxa64')
        platformInfo = 'Lnx64';
    elseif strcmpi(matlab.internal.addons.util.explorer.computerArch, 'win64')
        platformInfo = 'Win64';
    elseif strcmpi(matlab.internal.addons.util.explorer.computerArch, 'win32')
        platformInfo = 'Win32';
    else
        platformInfo = matlab.internal.addons.util.explorer.computerArch;
    end
end