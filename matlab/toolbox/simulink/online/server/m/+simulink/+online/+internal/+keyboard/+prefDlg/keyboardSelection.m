function layoutValue = keyboardSelection(varargin)
% function layoutValue = layoutChangeCallback(varargin)
% The option combobox needs to update when the selection on the keyboard
% combobox changes, but DDG does not allow updating the combobox entries on
% the widget, has to rely on the dialog refresh mechanism. But the
% selection value on the keyboard combobox will be gone after the dialog refresh.
% 
% The solution is to cache value in keyboardSelection, so that we can read it
% back on dialog refresh.
% 
% cachedlayoutValue = keyboardSelection();
% prevCachedlayoutValue = keyboardSelection(layoutValue);

% Copyright 2022 The MathWorks, Inc.

persistent cache;
layoutValue = cache;

if nargin == 1
    cache = varargin{1};
end

end