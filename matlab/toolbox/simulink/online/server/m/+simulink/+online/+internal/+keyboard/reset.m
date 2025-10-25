function reset()

%RESET resets keyboard to us layout and clear preference.
%   simulink.online.internal.reset() sets the keyboard layout to us layout
%   and clear saved preference.
 
%   Copyright 2021 The MathWorks, Inc.

slonline.setXKBMap('us');

prefGroup = 'simulink_online';
prefName = 'keyboard';

if ispref(prefGroup, prefName)
    rmpref(prefGroup, prefName);
end
    
end