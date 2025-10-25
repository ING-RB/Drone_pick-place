function setToggleCData(checkbox)
%Set the CData to mimic a toggle

%   Copyright 2017 The MathWorks, Inc.

if isappdata(checkbox, 'Value')
    f = ancestor(checkbox, 'figure');
    value = getappdata(checkbox, 'Value');
    if value
        file = 'opentoggle';
    else
        file = 'closedtoggle';
    end
    if sum(f.Color) < 1
        file = [file '_dark'];
    end

    im = getappdata(checkbox, 'Image');
    im.ImageSource = fullfile(fileparts(mfilename('fullpath')), [file '.png']);
else
    cData = [
        0 .5 NaN NaN NaN NaN NaN
        0 0  0   .5  NaN NaN NaN
        0 0  0   0   0   .5  NaN
        0 0  0   0   0   0   0
        0 0  0   0   0   .5  NaN
        0 0  0   .5  NaN NaN NaN
        0 .5 NaN NaN NaN NaN NaN];
    if checkbox.Value
        cData = transpose(cData);
    end
    cData = repmat(cData, 1, 1, 3);
    set(checkbox, 'CData', cData);
end

% [EOF]
