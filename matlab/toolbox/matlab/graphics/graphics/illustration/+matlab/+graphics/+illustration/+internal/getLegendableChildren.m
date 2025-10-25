function [chAll, chExcluded] = getLegendableChildren(ax,chIncluded)
%GET_LEGENDABLE_CHILDREN Gets the children for a legend
%  CH=GET_LEGENDABLE_CHILDREN(AX,N) returns the
%  legendable children for axes AX.

% Copyright 2004-2023 The MathWorks, Inc.
arguments
    ax
    chIncluded = []
end

legkids = allchild(ax);

% Take plotyy axes into account:
if matlab.graphics.illustration.internal.isplotyyaxes(ax)
    newAx = getappdata(ax,'graphicsPlotyyPeer');
    newChil = get(newAx,'Children');
    % The children of the axes of interest (passed in) should
    % appear lower in the stack than those of its plotyy peer.
    % The child stack gets flipud at the end of this function in
    % order to return a list in creation order.
    if ~isempty(newChil)
        legkids = [newChil(:); legkids(:)];
    else
        legkids = legkids(:);
    end            

end

if isempty(legkids)
    chAll = matlab.graphics.primitive.Data.empty;
    chExcluded = [];
    return
end

% exclude non-legendable objects
legkids = legkids(matlab.graphics.illustration.internal.islegendable(legkids));

% support for hggroup
legkids = matlab.graphics.illustration.internal.expandLegendChildren(legkids);

% We need to return a list of legendable children in creation order, but
% the axes 'Children' property returns a stack (reverse creation order).
% So we flip it.
chAll = flipud(legkids);

chExcluded = setdiff(chAll,chIncluded,'stable');