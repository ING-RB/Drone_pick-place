function chb = legendHitFcn(~,evt)
% This function, when used as a callback to a legend's "ItemHitFcn" will
% make the legend interactive. That is, clicking legend item will toggle
% visibility of the corresponding graphics object.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2020 The MathWorks, Inc.

chb = '☑';
if nargin == 0
    return
end
if evt.Peer.Visible
    evt.Peer.DisplayName = strrep(evt.Peer.DisplayName,chb,'☐');
else
    evt.Peer.DisplayName = strrep(evt.Peer.DisplayName,'☐',chb);
end
evt.Peer.Visible = ~evt.Peer.Visible;