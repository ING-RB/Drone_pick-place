function updateDropDownChecked(items, onTag)
%

%   Copyright 2020 The MathWorks, Inc.
on  = findobj(items, 'Tag', onTag);
off = setdiff(items, on);
for indx = 1:numel(off)
    off(indx).Value = false;
end
if isempty(on)
    return;
end
on.Value = true;

% [EOF]
