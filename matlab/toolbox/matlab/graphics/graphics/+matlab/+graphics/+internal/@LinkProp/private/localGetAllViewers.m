% Local functions called from processRemoveHandle()
%
function viewers = localGetAllViewers(hlist)

%   Copyright 2014-2023 The MathWorks, Inc.

viewers = {  };
for m = 1:length( hlist )
    viewer_axes = ancestor( hlist( m ), 'matlab.graphics.axis.AbstractAxes' );
    if ~isempty( viewer_axes )
        viewer = ancestor(viewer_axes,'matlab.ui.internal.mixin.CanvasHostMixin');
        if isempty( viewer )
            % if one of the objects doesn't have a viewer we say none do
            viewers = {  };
            return
        end
        if isempty( viewers ) || ~any( cellfun( @(a) eq( viewer, a ), viewers ) )
            viewers{ end + 1 } = viewer;  %#ok<AGROW>
        end
    end
end

end
