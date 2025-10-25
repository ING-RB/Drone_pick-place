function prevLayout = set(layout)
% sets layout as the keyboard layout and variant
% for Simulink Online and returns PREVLAYOUT as the previous keyboard
% layout. LAYOUT must be one of the supported keyboard layout names
% listed in simulink.online.internal.keyboard.supportedLayouts.

%   Copyright 2021 The MathWorks, Inc.

p = inputParser;
addRequired(p, 'layout', @(x)validateattributes(x, {'char'}, {'nonempty'}));
parse(p, layout);

layout = p.Results.layout;

prevLayout = simulink.online.internal.keyboard.get();

xkbParams = split(layout, '.');
slonline.setXKBMap(xkbParams{:});

prefGroup = simulink.online.internal.Preference.groupName();
prefName = 'keyboard';

setpref(prefGroup, prefName, layout);

end
