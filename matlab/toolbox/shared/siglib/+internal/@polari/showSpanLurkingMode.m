% function showSpanLurkingMode(p) % Shashank, Vish
% Start span mode without adding cursors.
%
% Span silently awaits sufficient cursors to show itself.

% This is inefficient and slows startup time. It adds two
% markers then deletes them. Better would be to NOT add the
% markers, yet remain in the same end-state.
%   showAngleSpan(p);
%   removeAngleMarkers(p);
%
% Create "always on" angle span
% if isempty(p.hAngleSpan)
%     p.hAngleSpan = internal.polariAngleSpan;
%     initLurking(p.hAngleSpan,p);
% end
