function enableToolbarOnButtonDown(ax_or_uiaxes)
%ENABLETOOLBARONBUTTONDOWN enables interactions on buttondown

% This function disables the axes toolbar and enables it again on the first
% buttondown. Subsequent buttondowns have no effect.

%   Copyright 2019 The MathWorks, Inc.

ax = findobjinternal(ax_or_uiaxes,'-isa','matlab.graphics.axis.AbstractAxes');
ax.Toolbar.Visible = 'off';

a = addlistener(ax,'Hit',@(o,e)noop());
a.Callback = @(o,e)enableToolbarAndDelete(ax, a);
end

function enableToolbarAndDelete(ax, a)
    ax.Toolbar.Visible = 'on';

    delete(a);
end
