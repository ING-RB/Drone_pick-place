function resetKeyboard()
%RESETKEYBOARD resets keyboard to us layout and clear preference.
%   simulink.online.resetKeyboard() sets the keyboard layout to us layout
%   and clear saved preference.
 
%   Copyright 2021 The MathWorks, Inc.

simulink.online.internal.keyboard.reset();