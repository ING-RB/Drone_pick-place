function hoverfig(varargin)
%HOVERFIG  Use HOVERFIG as the figure's WindowButtonMotionFcn to
%          dynamically modify pointer shape and activate data
%          markers where appropriate.  

%   Author: John Glass
%   Copyright 1986-2014 The MathWorks, Inc.

persistent LM HBF Point
if nargin<3
    fig = varargin{1};    
elseif nargin>3
    %% This is the case where the stick callback function is executed.
    fig = ancestor(LM,'figure');
    set(Point, 'ButtonDownFcn', HBF);
    set(LM,'ButtonDownFcn',[]);
    LM = [];Point = [];
    return;
end

figh = handle(fig);
% Only process mouse event if not in a scribemode. (g388926)

ModeManager = uigetmodemanager(figh);
if ~isempty(ModeManager.CurrentMode)
    return
end

hoverobj = handle(hittest(fig));

%Check whether the hit object is part of a tip
isTip = false;
if ~isempty(LM)
	isTip = ~isempty(ancestor(hoverobj, class(LM)));
end

objtag = '';
if isprop(hoverobj, 'Tag')
    objtag  = hoverobj.Tag;
end

if ~isTip && ...
        ~any(strcmpi(objtag,{'CharPoint','PZ_Zero','PZ_Pole'})) && ...
        (ishghandle(hoverobj, 'figure') || ishghandle(hoverobj, 'uicontrol') ...
        || ishghandle(hoverobj, 'axes') || ishghandle(hoverobj, 'line') || ...
        ishghandle(hoverobj, 'hggroup'))

    if ishghandle(LM)
        % Remove the current cursor
       delete(LM);
       LM = [];
                end
    
    if ~isempty(Point) && ishghandle(Point)
        % Restore ButtonDownFcn on Point
                set(Point, 'ButtonDownFcn', HBF);
        Point = [];
        HBF = [];
        end     
end

switch objtag
case {'CharPoint','PZ_Zero','PZ_Pole'}
    %---Workaround for non-moveable markers
    if ishghandle(LM)
        return
    end    
    HBF = get(hoverobj,'ButtonDownFcn');
    if ~isempty(HBF)
        if isa(HBF,'cell')
            hoverbdf = {HBF{1},hoverobj,[],HBF{2:end}};
        else
            hoverbdf = {HBF,hoverobj,[]};
        end
        %hoverbdf;
        %% Store the handle to the characteristic point and clear the
        %% button down function.
        Point = hoverobj;
        set(Point, 'ButtonDownFcn', []);
        %% Evaluate to create the datatip
        LM = feval(hoverbdf{:});
        if isempty(LM), return, end
        %% Set the line marker properties to match those on the points
        %% below.
        FaceColor = get(hoverobj,'MarkerFaceColor');
        Marker = get(hoverobj,'Marker');
        MarkerSize = get(hoverobj,'MarkerSize'); 
        MarkerEdgeColor = get(hoverobj,'MarkerEdgeColor');
        if strcmp(MarkerEdgeColor,'auto')
            MarkerEdgeColor = get(hoverobj,'Color');
        end
        
            set(LM,'Marker',Marker,...
                'MarkerFaceColor',FaceColor,...
                'MarkerSize',MarkerSize,...
                'MarkerEdgeColor',MarkerEdgeColor,...
                'ButtonDownFcn',{@localStick,fig});
        
        hTool = datacursormode(fig);
        addDataCursor(hTool,LM);
    end

end

%%%%%%%%%%%%%%
% localStick %
%%%%%%%%%%%%%%
function localStick(eventSrc,eventData,fig)

hoverfig([],[],fig,'stick');