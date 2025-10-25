function ax = getAxesInParent(parent, create)
% This function is undocumented and may change in a future release.

% This function will return an axes/chart in the specified parent container
% (such as Figure, Tab, or Panel). If CREATE is true, the output is
% guaranteed to be a valid axes or chart that is a direct child of the
% specified parent container.
% 
% * If no parent is provided, or the specified parent is invalid or empty,
% this function is equivalent to gca.
%
% * If a valid parent is specified, and the CurrentAxes of the ancestor
% figure is in the specified parent, then this function will return the
% CurrentAxes.
% 
% * If the CurrentAxes of the ancestor figure is not in the specified
% parent, or if there is no figure (and thus no CurrentAxes), and the
% specified parent has a child that is an axes or chart, then the first
% axes/chart child of the specified parent will be returned.
% 
% * If the specified parent has no child axes or charts, then a new axes
% will be created in the specified parent (unless CREATE is false).

%   Copyright 2015-2023 The MathWorks, Inc.

% Make sure we have a valid parent. This will create a figure if one does
% not already exist.
if nargin == 0 || isempty(parent) || ~isgraphics(parent)
    parent = gcf;
end

% Determine whether to create an axes if one is not found.
if nargin < 2
    create = true;
end

% Initialize an empty graphics object array.
ax = gobjects(0);

% Get the figure that contains the requested parent container.
fig = ancestor(parent,'figure');
if ~isempty(fig)
    % Get the current axes of the figure.
    currentaxes = fig.CurrentAxes;
end

if ~isempty(fig) && isempty(currentaxes)
    % There are no axes in the figure, so create a new axes in the
    % specified parent container.
    if(create) 
        ax = axes('Parent',parent);
    end
elseif ~isempty(fig) && currentaxes.Parent == parent
    % The current axes of the figure is in the specified parent container,
    % so we can use that axes.
    ax = currentaxes;
else
    % The current axes of the figure is not in the specified parent
    % container, so we need to see if there are any existing axes or charts
    % in that container.
    if isprop(parent, 'Children')
        children = findobj(parent.Children,'flat',...
            '-isa','matlab.graphics.mixin.CurrentAxes');
    else
        children = gobjects(0);
    end

    if isempty(children)
        % There are no axes in the parent, so create a new axes in the
        % specified parent container.
        if(create)
            ax = axes('Parent',parent);
        end
    else
        % There are axes in this parent container, use the first one in
        % the child order, which will be the last axes created.
        ax = children(1);
    end
end

end
