function hpanel = getimscrollpanel(h_over)
%GETIMSCROLLPANEL
%   This is an undocumented function and may be removed in a future release.

%GETIMSCROLLPANEL Get image scrollpanel.
%   HPANEL = GETIMSCROLLPANEL(H_OVER) returns the imscrollpanel associated
%   with H_OVER. H_OVER may be of type axes or image. If no imscrollpanel is
%   found, GETIMSCROLLPANEL returns an empty matrix.

%   Copyright 2004-2013 The MathWorks, Inc.

hpanel = [];
firstPanelAncestor = ancestor(h_over,'uipanel');
if strcmp(get(firstPanelAncestor,'tag'),'imscrollpanel') || ...
    strcmp(get(firstPanelAncestor,'tag'),'LeftScrollPanel') || ...
    strcmp(get(firstPanelAncestor,'tag'),'RightScrollPanel')
    
    hpanel = firstPanelAncestor;
% else
%     
%     secondPanelAncestor = ancestor(firstPanelAncestor,'uipanel');
%     if strcmp(get(secondPanelAncestor,'tag'),'imscrollpanel')
%         hpanel = secondPanelAncestor;
%     end
end

