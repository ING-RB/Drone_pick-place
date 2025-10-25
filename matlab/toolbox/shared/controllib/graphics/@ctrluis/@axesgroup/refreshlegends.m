function refreshlegends(this,varargin)
% REFRESHLEGENDS Refreshes the legends for the axesgroup

%  Author(s): C. Buhr
%  Copyright 1986-2015 The MathWorks, Inc.

ax = this.Axes2d(:);
ax = ax(ishghandle(ax,'axes'));

if nargin>1
    ax = ax(varargin{1});
end

parent = this.Parent;

% Find all legends
legax = findobj(get(parent,'Children'),'flat','Tag','legend');

% Refresh legends
warn = ctrlMsgUtils.SuspendWarnings;
for ct = 1:length(legax)
    leg = legax(ct);
    if isa(handle(leg),'matlab.graphics.illustration.Legend')
        % Get axes that legend is associated with
        targetax = get(leg,'axes');

        % Check if its a legend for the @axesgroup
        if any(double(targetax)==double(ax(:)))
            if strcmpi(get(targetax,'visible'),'off')
                legend(double(targetax),'off')
            end
        end
    end
end
delete(warn);



