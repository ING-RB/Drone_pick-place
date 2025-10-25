function varargout = colormapeditor(obj, varargin)
%COLORMAPEDITOR Open Colormap Editor
%
%   colormapeditor opens the Colormap Editor. Use the Colormap Editor to customize the colormap of the selected axes or figure.
%
%   See also COLORMAP
%

%   Copyright 1984-2022 The MathWorks, Inc.

varargout = {};

% look for figure input
if nargin    
    % colormapeditor([]) should do nothing
    if isempty(obj)
        return
    end
    
    if nargin == 1
        if isa(obj,'matlab.graphics.chart.Chart')
            error(message('MATLAB:colormapeditor:UnsupportedObject', obj.Type));
        end
        if ~any(ishandle_valid(obj)) || (~isgraphics(obj,'figure') ...
                && ~isgraphics(obj,'matlab.graphics.axis.AbstractAxes')) || ...
                (isgraphics(obj,'figure') && strcmpi(get(obj, 'HandleVisibility'),'off'))
            error(message('MATLAB:colormapeditor:InvalidFigureHandle'));
        end
    end
else
    obj = [];
end

% get figure if not provided or if HandleVisibility is off
if isempty(obj) ||...
        ~strcmpi(get(obj, 'HandleVisibility'),'on') % Colormap editor does not support handle visibility off
    obj = get(0,'CurrentFigure');
    if isempty(obj) || ~strcmpi(get(obj, 'HandleVisibility'),'on') % g1038597
        obj = gcf;
    end
    axObj = get(obj,'CurrentAxes');
    if ~isempty(axObj)
        obj = axObj;
    end
end

% make sure the colormap is valid
check_colormap(colormap(obj))

% reuse the only one if it's there
cme = get_cmapeditor();
if ~isempty(cme)
    cme.bringToFront;
    cme.setVisible;
    return;
end

if ishghandle(handle(obj),'figure')
    ax = get(obj,'CurrentAxes');
    fig = handle(obj);
elseif isa(handle(obj),'matlab.graphics.axis.AbstractAxes')
    ax = obj;
    fig = handle(ancestor(obj,'figure'));
else
    fig = handle(gcf);
    ax = get(fig,'CurrentAxes');
end

cme = datamanager.colormapeditor.ColormapEditorController(fig);
% all figure and axes listeners must be destroyed once colormap editor
% is closed so that listeners do not leak - g2521481
addlistener(cme.ColormapEditor,'EditorClosed',@(e,d) kill_listeners(fig));
set_cmapeditor(cme);

if ~isprop(ax,'clim')
    ax = [];
end
set_current_object(obj);
cme.setFigure(fig);
start_listeners(fig, ax);

% all set, show it now
update_colormap(colormap(obj));


%----------------------------------------------------------------------%
%   MATLAB listener callbacks
%----------------------------------------------------------------------%
function currentFigureChanged(hProp, eventData, oldfig, oldax) %#ok<INUSL>
fig = get(0, 'CurrentFigure');
if isempty(fig) || handle(fig)==handle(oldfig) ||  ~strcmpi(get(fig, 'HandleVisibility'),'on') % g1038597
    % Nothing to do here, since it's the same figure or the current figure
    % has handle visibility off
    return;
end
set_current_object(fig);
set_current_figure(fig,oldfig,oldax);

%----------------------------------------------------------------------%
%   Figure listener callbacks
%----------------------------------------------------------------------%
function cmapChanged(~, ~, obj)

% hProp is not used
try
    update_colormap(colormap(obj));
    
    % The CLim may not have been set in the initialization and a PostSet
    % may not fire so we need to update the clim too if the ColorSpace is
    % updated g1079308
    if ishghandle(obj,'axes')
        climChanged([],[],obj);
    end
catch err
    warning(err.identifier,'%s',err.message);
end

%----------------------------------------------------------------------%
function currentAxesChanged(hProp, eventData, oldfig, oldax) %#ok<INUSL>

ax = get(eventData.AffectedObject,'CurrentAxes');

if isempty(ax) || ~isvalid(ax)
    return;
end

set_current_axes(ax,oldfig,oldax);
set_current_object(ax);
% Calling drawnow to make colormap of axes get set to default values
% If we don't do this an initialization can happen afterwards making the
% UI flash from one colormap to another.  This is because the original
% colormap is Jet but changed to parula for the new handle graphics.
drawnow;
obj = get_current_object();
if ~ishandle_valid(obj)
    return;
end
cmap = colormap(obj);
update_colormap(cmap);

%-----------------------------------------------------------------------%
function updateTitle(~,~)

cme = get_cmapeditor();
if isempty(cme)
    return
end
set_cme_title(cme);

%------------------------------------------------------------------------%
function handle_mouse_released(~,~,~,~)

obj = get_current_matlab_object();
set_current_object(obj);
cme = get_cmapeditor();
if ~isempty(cme)
    if ishghandle(obj,'figure')
        update_colormap(colormap(obj));
        enableResetAxes(cme,false);
    elseif isa(obj,'matlab.graphics.axis.AbstractAxes')
        update_colormap(colormap(obj));
        enableResetAxes(cme,true);
    end
end

%-----------------------------------------------------------------------%
function figureDestroyed(hProp,eventData,oldfig,oldax) %#ok<INUSL>

allFigs = findobj(0,'type','figure','handlevisibility','on');
nfigs = length(allFigs);
% We need to check that get_cmapeditor is not empty here because when
% the test point tcolormapeditor lvlTwo_Listeners is run,
% the call to close all closes the figure
% linked to the ColorMapEditor after the unlinked figure, so nfigs==1 %
% then this callback fires. In this case kill_listeners expects
% that a getappdata(0,'CMEditor') is not empty, which it normally would not
% be but in the testpoint appdata(0,'CMEditor') was cleared.
cme = get_cmapeditor();
if ~isempty(cme)
    cme.removeObject(eventData.Source);
end
if nfigs<=1 && ~isempty(get_cmapeditor)% the one being destroyed
    destroy_matlab_listeners;
    destroy_figure_listeners(oldfig);
    destroy_axes_listeners(oldax);
    kill_listeners(oldfig);
else
    fig = get(0,'CurrentFigure');
    fig = handle(fig);
    %if fig is the figure currently being destroyed, we need to get the figure
    %that is previously being referred to
    if (fig == eventData.Source)
        for i = 1:length(allFigs)
            if allFigs(i) ~= eventData.Source
                fig = handle(allFigs(i));
                break;
            end
        end
    end
    %---------------------------------------------------------------------
    set_current_object(fig);
    set_current_figure(fig,oldfig,oldax);
end

%----------------------------------------------------------------------%
%   Axes Listener Callbacks
%----------------------------------------------------------------------%
function climChanged(hProp, eventData, ax) %#ok<INUSL>

cme = get_cmapeditor();
if isempty(cme)
    return
end
clim = get(ax,'Clim');
cme.setColorLimits(clim);

%----------------------------------------------------------------------%
function axesDestroyed(hProp, eventData, oldfig, oldax) %#ok<INUSL>

cme = get_cmapeditor();
if isempty(cme)
    return;
end
cme.removeObject(eventData.Source);

fig = handle(cme.getFigure); % Remove java wrapper
if ~any(ishandle_valid(fig))
    return;
end
ax = get(fig,'currentaxes');
if ~ishandle_valid(ax)
    set_current_object(fig);
else
    set_current_object(ax);
end
set_current_axes(ax,oldfig,oldax);
update_colormap(colormap(fig));

%------------------------------------------------------------------------%
function handleAxesReset(~,~,ax)

al = get(ax,'CMEditAxListeners');
ax.Title;
drawnow;
delete(al.titleSet);
al.titleSet = event.listener(ax.Title,'MarkedClean', ...
    @(es,ed) updateTitle(es,ed));
set(ax,'CMEditAxListeners',al);

%----------------------------------------------------------------------%
%   Helpers
%----------------------------------------------------------------------%
function set_current_figure(fig,oldfig,oldax)

if ~any(ishandle_valid(fig)) || isequal(fig,oldfig) ||...
        ~strcmpi(get(fig, 'HandleVisibility'),'on') % g1038597
    return;
end

if strncmpi (get(handle(fig),'Tag'), 'Msgbox', 6) || ...
        strcmpi (get(handle(fig),'Tag'), 'Exit') || ...
        strcmpi (get(handle(fig),'WindowStyle'), 'Modal')
    return;
end

cme = get_cmapeditor();
if isempty(cme)
    return;
end

ax = get(fig,'CurrentAxes');
if ~isprop(ax,'clim')
    ax = [];
end
% get rid of old figure listeners
destroy_figure_listeners(oldfig);
% get rid of old axes listeners
destroy_axes_listeners(oldax);
cme.setFigure (handle(fig));
create_matlab_listeners(fig,ax);
create_figure_listeners(fig,ax);

handle_axes_change(fig,ax,true);

%------update colormap when figure deleted-------
update_colormap(colormap(fig));

%----------------------------------------------------------------------%
function set_current_axes(ax,oldfig,oldax)

if ~any(ishandle_valid(ax)) || isequal(ax,oldax) || ~isprop(ax,'clim')
    return;
end

fig = ancestor(ax,'figure');

% get rid of old axes listeners
destroy_axes_listeners(oldax);

% if the new axes is invalid, get out now
if ~any(ishandle_valid(ax))
    kill_listeners(oldfig);
    return;
end

create_matlab_listeners(fig,ax);
create_figure_listeners(fig,ax);
handle_axes_change(fig,ax,true);






%----------------------------------------------------------------------%
function start_listeners(fig,ax)

create_matlab_listeners(fig,ax);
create_figure_listeners(fig,ax);
handle_axes_change(fig,ax,true);



%----------------------------------------------------------------------%
function kill_listeners(fig)

% make sure the colormap editor is gone
cme = get_cmapeditor();
if isempty(cme)
    error(message('MATLAB:colormapeditor:ColormapeditorAppdataExpected'))
end
cme.close;

% we need to kill these now, otherwise we'll leak the listeners and
% they will continue to fire after this colormap editor is gone
destroy_matlab_listeners

if any(ishandle_valid(fig))
    destroy_figure_listeners(fig);
    
    % axes
    ax = get(fig,'CurrentAxes');
    
    % return if no current axes or it is being destroyed
    if any(ishandle_valid(ax))
        destroy_axes_listeners(ax);
    end
end

% now flush out the cmap editor handle
rm_cmapeditor();

%----------------------------------------------------------------------%
function create_matlab_listeners(fig,ax)

rt = handle(0);
ml.cfigchanged = event.proplistener(rt,rt.findprop('CurrentFigure'), ...
    'PostSet',@(es,ed) currentFigureChanged(es,ed,fig,ax));
setappdata(0,'CMEditMATLABListeners',ml);

%----------------------------------------------------------------------%
function destroy_matlab_listeners

if isappdata(0,'CMEditMATLABListeners')
    % we actually need to delete these handles or they
    % will continue to fire
    ld = getappdata(0,'CMEditMATLABListeners');
    fn = fields(ld);
    for i = 1:length(fn)
        l = ld.(fn{i});
        if ishghandle(l)
            delete(l);
        end
    end
    rmappdata(0,'CMEditMATLABListeners');
end

%----------------------------------------------------------------------%
function create_figure_listeners(fig,ax)

if any(ishandle_valid(fig))
    
    fig = handle(fig);
    fl.deleting = event.listener(fig, ...
        'ObjectBeingDestroyed', @(es,ed) figureDestroyed(es,ed,fig, ax));
    fl.cmapchanged = event.proplistener(fig,fig.findprop('Colormap'), ...
        'PostSet',@(es,ed) cmapChanged(es,ed,fig));
    fl.caxchanged = event.proplistener(fig, fig.findprop('CurrentAxes'), ...
        'PostSet',@(es,ed) currentAxesChanged(es,ed,fig,ax));
    fl.numberTitle = event.proplistener(fig, fig.findprop('NumberTitle'), ...
        'PostSet',@(es,ed) updateTitle(es,ed));
    fl.nameSet = event.proplistener(fig, fig.findprop('Name'), ...
        'PostSet',@(es,ed) updateTitle(es,ed));
    fl.mouseDown = event.listener(fig, 'WindowMouseRelease', ...
        @(es,ed) handle_mouse_released(es,ed,fig,ax));
    setappdata(fig,'CMEditFigListeners',fl);
end

%----------------------------------------------------------------------%

function enable_figure_listeners(fig,onoff)

if ~isempty(fig) && any(ishandle_valid(fig, 'CMEditFigListeners'))
    fl = getappdata(fig,'CMEditFigListeners');
    if isobject(fl.cmapchanged)
        fl.cmapchanged.Enabled = strcmpi(onoff,'on');
    else
        set(fl.cmapchanged,'Enabled',onoff);
    end
    if isobject(fl.caxchanged)
        fl.caxchanged.Enabled = strcmpi(onoff,'on');
    else
        set(fl.caxchanged,'Enabled',onoff);
    end
    if isobject(fl.deleting)
        fl.deleting.Enabled = strcmpi(onoff,'on');
    else
        set(fl.deleting,'Enabled',onoff);
    end
    if isobject(fl.numberTitle)
        fl.numberTitle.Enabled = strcmpi(onoff,'on');
    else
        set(fl.numberTitle,'Enabled',onoff);
    end
    if isobject(fl.nameSet)
        fl.nameSet.Enabled = strcmpi(onoff,'on');
    else
        set(fl.nameSet,'Enabled',onoff);
    end
    if isobject(fl.mouseDown)
        fl.mouseDown.Enabled = strcmpi(onoff,'on');
    else
        set(fl.mouseDown,'Enabled',onoff);
    end
    setappdata(fig,'CMEditFigListeners',fl);
end

%----------------------------------------------------------------------%
function destroy_figure_listeners(fig)

enable_figure_listeners(fig,'off');
if any(ishandle_valid(fig, 'CMEditFigListeners'))
    rmappdata(fig,'CMEditFigListeners');
end

%----------------------------------------------------------------------%
function create_axes_listeners(fig,ax)

if any(ishandle_valid(ax))
    al.deleting = event.listener(ax, ...
        'ObjectBeingDestroyed',@(es,ed) axesDestroyed(es,ed,fig,ax));
    al.climchanged = event.proplistener(ax,ax.findprop('CLim'), ...
        'PostSet', @(es,ed) climChanged(es,ed,ax));
    al.cmapchanged = event.listener(ax.ColorSpace,'MarkedClean', ...
        @(es,ed) cmapChanged(es,ed,ax));
    % Forced creation of delayed axes property
    ax.Title;drawnow;
    al.titleSet = event.listener(ax.Title,'MarkedClean', ...
        @(es,ed) updateTitle(es,ed));
    al.reset = event.listener(ax,'Reset', ...
        @(es,ed) handleAxesReset(es,ed,ax));
    if ~isprop(ax,'CMEditAxListeners')
        % Add a transient dynamic property CMEditAxListeners on axes to store
        % listeners. Earlier, we were using appdata but that triggers
        % morphing when in MOL g2217842
        cmEditProp = addprop(ax,'CMEditAxListeners');
        cmEditProp.Hidden = true;
        cmEditProp.Transient = true;
    end
    set(ax,'CMEditAxListeners',al);
end


%----------------------------------------------------------------------%
function enable_axes_listeners(ax,onoff)

fig = get(0,'CurrentFigure');
if ~isempty(fig) && any(ishandle_valid(ax, 'CMEditAxListeners'))
    al = get(ax,'CMEditAxListeners');
    if isobject(al.climchanged)
        al.climchanged.Enabled = strcmpi(onoff,'on');
    else
        set(al.climchanged,'Enabled',onoff);
    end
    if isobject(al.deleting)
        al.deleting.Enabled = strcmpi(onoff,'on');
    else
        set(al.deleting,'Enabled',onoff);
    end
    if isobject(al.cmapchanged)
        al.cmapchanged.Enabled = strcmpi(onoff,'on');
    else
        set(al.cmapchanged,'Enabled',onoff);
    end
    if isobject(al.titleSet)
        al.titleSet.Enabled = strcmpi(onoff,'on');
    else
        set(al.titleSet,'Enabled',onoff);
    end
    set(ax,'CMEditAxListeners',al);
end

%----------------------------------------------------------------------%
function destroy_axes_listeners(ax)

enable_axes_listeners(ax,'off');
if isprop(ax,'CMEditAxListeners')
    % Delete the dynamic property that store axes listeners
    delete(findprop(ax,'CMEditAxListeners'));
end

%----------------------------------------------------------------------%
function update_colormap(cmap)

check_colormap(cmap);
cme = get_cmapeditor();
if ~isempty(cme)
    if  ~isempty(cme.ColormapEditor)
        cme.setBestColorMapModel(cmap);
    end
    set_cme_title(cme);
end

%----------------------------------------------------------------------%
function yesno = ishandle_valid(h,appdata_field)

narginchk(1,2);
if nargin == 1
    appdata_field = [];
end
yesno = any(ishghandle(h)) && ~strcmpi('on',get(h,'BeingDeleted'));
if yesno && ~isempty(appdata_field)
    yesno = yesno && isappdata(h,appdata_field);
end

%----------------------------------------------------------------------%
function handle_axes_change(fig,ax,create_listeners)

cme = get_cmapeditor();
if isempty(cme)
    return;
end

if ~any(ishandle_valid(ax))
    cme.setColorLimitsEnabled(0);
else
    clim = get(ax,'Clim');
    cme.setColorLimitsEnabled(1);
    cme.setColorLimits(clim);
    if (create_listeners)
        create_axes_listeners(fig,ax);
    end
end


%----------------------------------------------------------------------%
function check_colormap(cmap)
if isempty(cmap)
    error(message('MATLAB:colormapeditor:ColormapEmpty'));
end

%----------------------------------------------------------------------%
function cme = get_cmapeditor
cme = getappdata(0,'CMEditor');

%----------------------------------------------------------------------%
function set_cmapeditor(cme)
setappdata(0,'CMEditor',cme);

%----------------------------------------------------------------------%
function rm_cmapeditor
rmappdata(0,'CMEditor');

%-----------------------------------------------------------------------%
% the function sets obj to the current working object, could be either axes or
% figure. If a surface is selected then, the current working object is the
% axes that contains the surface.
function obj = get_current_matlab_object()

obj = gco;

if ~isempty(obj)
    if ishghandle(obj,'Colorbar')
        obj = obj.Axes;
    elseif ~ishghandle(obj,'figure') && ~isa(obj,'matlab.graphics.axis.AbstractAxes')
        obj = ancestor(obj, 'matlab.graphics.axis.AbstractAxes');
        if ~ishandle_valid(obj)
            obj = '';
        end
        
        if isempty(obj)
            obj = get(0,'CurrentFigure');
        end
    end
end

if isempty(obj) || (~ishghandle(obj,'figure') && ~ishghandle(obj,'axes'))
    fig = get(0,'CurrentFigure');
    ax = get(fig, 'currentaxes');
    if ~isempty(ax) && isprop(ax,'clim')
        obj = ax;
    else
        obj = fig;
    end
end

%----------------------------------------------------------------------%
function set_current_object(obj)

if ishandle_valid(obj)
    cme = get_cmapeditor();
    if ~isempty(cme)
        cme.setCurrentObject(handle(obj));
    end
end

%----------------------------------------------------------------------%
function obj = get_current_object()

obj = [];
cme = get_cmapeditor();
if isempty(cme)
    return;
end
obj = handle(cme.getCurrentObject());
if isempty(obj)
    obj = get_current_matlab_object;
    set_current_object(obj);
end

%----------------------------------------------------------------------%
%set the title to be displayed in the colormapeditor, G950928
function set_cme_title(cme)

if isempty(cme)
    return
end
obj = get_current_object();
if ~ishandle_valid(obj)
    return;
end

if ~ishghandle(obj,'figure')
    fig = ancestor(obj, 'figure');
else
    fig = obj;
end

figureNumber = num2str(fig.Number);
title = '';
separator = '';
if strcmpi(get(fig,'NumberTitle'),'on')
    title = [getString(message('MATLAB:uistring:colormapeditor:FigureTitle')) ' ' figureNumber];
    separator = ': ';
end
if ~isempty(get(fig,'Name'))
    title = [title separator get(fig,'Name')];
end

if isa(obj,'matlab.graphics.axis.AbstractAxes')
    axestitle = get_axes_title(obj);
    title = [title ': ' axestitle];
end

title = [title ' - ' getString(message('MATLAB:datamanager:colormapeditor:ColorData'))];

currentText = cme.getCurrentItemLabel();
if ~strcmp(currentText,title)
    cme.setCurrentItemLabel(title);
end

%---------------------------------------------------------------------- %
%enables Reset current Axes Colormap when the current working object is an axes
function enableResetAxes(cme,state)
cme.enableResetAxes(state);


function axestitle = get_axes_title(ax)
% Return the title of an axes as a 1D string.
%
% @todo This (and the functions above) need unittests!
%
axestitle = '';
if ~isempty(ax.Title) && ~isempty(ax.Title.String)
    title_string = ax.Title.String;
    if ischar(title_string)
        if size(title_string,1) == 1
            axestitle = title_string;
        elseif (size(title_string,1) > 1)
            title_string = title_string';
            title_string = title_string(:)';
        end
        if ~isempty(title_string)
            axestitle = title_string;
        end
    elseif iscell(title_string)
        axestitle = strjoin(title_string);
    end
else
    axestitle = getString(message('MATLAB:uistring:colormapeditor:UntitledAxes'));
end
