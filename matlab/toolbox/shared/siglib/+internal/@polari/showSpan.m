function ret = showSpan(p,id1,id2,reorder)
%showSpan Show angle span between two markers.
%  showSpan(P,ID1,ID2) displays an angle span between two
%  angle markers identified by ID1 and ID2, taken from ID1 to
%  ID2 in the counter-clockwise direction.  Marker identifiers
%  are 'C1', 'C2', ... for cursor markers and 'P1', 'P2', ...
%  for peak markers.  The numerical difference in angle and
%  magnitude between the markers is also displayed.
%
%  showSpan(P,ID1,ID2,true) automatically reorders the angle
%  markers such that the initial angle span is <= 180 degrees
%  as measured in the counter-clockwise direction.
%
%  showSpan(p,VIS) sets angle span visibility by setting VIS to
%  true or false.  Alternatively, set property P.Span to true
%  or false.
%
%  showSpan(p) toggles the angle span display on and off.
%
%  One or two angle markers are automaticaly added to the plot
%  if two markers are not present when angle span is enabled.
%
% D = showSpan(...) returns angle span details as a structure
% D, and is the same structure as returned by property
% P.SpanDetails.
%
% See also polarpattern.

s = p.hAngleSpan;

if nargin == 1
    % Toggle span display
    if isempty(s) || ~s.Visible
        newVis = true;
    else
        newVis = false;
    end
    showAngleSpan(p,newVis);
    
    return % EARLY EXIT
    
elseif nargin == 2
    % Set span visibility
    if ischar(id1) || ~isscalar(id1)
        error(message('siglib:polari:errorInputscaslar'));
    end
    showAngleSpan(p,logical(id1));
    
    return % EARLY EXIT
end

% Always enable span display if IDs specified
if isempty(s)
    showAngleSpan(p,true)
    s = p.hAngleSpan;
end

% Record these in CCW order as expected by caller.
%
% Allow lowercase and append ".1" for peak marker IDs as needed:
ids = expandAndCheckMarkerName(p,{id1,id2});
if isequal(ids{1},ids{2})
    error(message('siglib:polari:errorSpanendpoints'));
end

% Preserve initial angles > 180 degrees if requested
% (e.g., polariAntenna does this)
if nargin > 3
    %oldReflex = s.PreserveReflexAngle;
    s.PreserveReflexAngle = ~reorder;
end
% Set new IDs
s.SpanIDs_LiveUpdate = upper(ids);
% Once span is visible, we can revert the reflex flag
if nargin > 3
    s.PreserveReflexAngle = true; % oldReflex;
end

s.Visible = true;
if nargout > 0
    ret = p.SpanDetails;
end
