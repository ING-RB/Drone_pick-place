function [retval] = resetplotview(hAxes,varargin)
% Internal use only. This function may be removed in a future release.

% Copyright 2003-2023 The MathWorks, Inc.

% This helper is used by zoom, pan, and tools menu
%
% RESETPLOTVIEW(AX,'InitializeCurrentView') 
%     Saves current view only if no view information already exists. 
% RESETPLOTVIEW(AX,'BestDataFitView') 
%     Reset plot view to fit all applicable data
% RESETPLOTVIEW(AX,'SaveCurrentView') 
%     Stores view state (limits, camera) 
% RESETPLOTVIEW(AX,'SaveCurrentViewPropertyOnly') 
%     Stores a new View property only
% RESETPLOTVIEW(AX,'SaveCurrentViewLimitsOnly') 
%     Stores new Limits only
% RESETPLOTVIEW(AX,'GetStoredViewStruct') 
%     Retrieves view information in the form of a structure. 
% RESETPLOTVIEW(AX,'SetViewStruct',VIEWSTRUCT)
%     Sets the view information from the supplied struct
% RESETPLOTVIEW(AX,'ApplyStoredView') 
%     Apply stored view state to axes
% RESETPLOTVIEW(AX,'ApplyStoredViewLimitsOnly') 
%     Apply axes limit in stored state to axes
% RESETPLOTVIEW(AX,'ApplyStoredViewViewAngleOnly')
%     Apply axes camera view angle in stored state to axes


if any(isempty(hAxes)) || ...
  ~any(isgraphics(hAxes,'axes') | isgraphics(hAxes,'polaraxes'))
    return;
end

hAxes = matlab.graphics.interaction.internal.getLinkedAxes(hAxes);

for n = 1:length(hAxes)
    retval = localResetPlotView(hAxes(n),varargin{:});
end

%--------------------------------------------------%
function [retval] = localResetPlotView(hAxes,varargin)

retval = [];
if nargin<2
  localAuto(hAxes);
  return;
end

if isa(hAxes,'matlab.graphics.axis.PolarAxes')
    return;
end

KEY = 'matlab_graphics_resetplotview';
switch varargin{1}
    case 'InitializeCurrentView'
        viewinfo = getappdata(hAxes,KEY);
        if isempty(viewinfo)
            viewinfo = localCreateViewInfo(hAxes);
            setappdata(hAxes,KEY,viewinfo);                
        end
    case 'SaveCurrentView'
        viewinfo = localCreateViewInfo(hAxes);
        setappdata(hAxes,KEY,viewinfo);  
    case 'SaveCurrentViewPropertyOnly'
        viewinfo = localViewPropertyInfo(hAxes, KEY);
        setappdata(hAxes,KEY,viewinfo); 
    case 'SaveCurrentViewLimitsOnly'
        viewinfo = localLimitsInfo(hAxes, KEY);
        setappdata(hAxes,KEY,viewinfo); 
    case 'GetStoredViewStruct'
        retval = getappdata(hAxes,KEY);
    case 'SetViewStruct'
        viewinfo = varargin{2};
        setappdata(hAxes,KEY,viewinfo);
    case 'ApplyStoredView'
        viewinfo = getappdata(hAxes,KEY);
        viewinfo = hAxes.InteractionOptions.applyRestoredLimits(hAxes,viewinfo);
        localApplyViewInfo(hAxes,viewinfo);
    case 'ApplyStoredViewLimitsOnly'
        viewinfo = getappdata(hAxes,KEY);
        viewinfo = hAxes.InteractionOptions.applyRestoredLimits(hAxes,viewinfo);
        localApplyLimits(hAxes,viewinfo);
    case 'ApplyStoredViewViewAngleOnly'
        viewinfo = getappdata(hAxes,KEY);
        localApplyViewAngle(hAxes,viewinfo);
    otherwise
        error(message('MATLAB:resetplotview:invalidInput'));
end

%----------------------------------------------------%
function [viewinfo] = localApplyViewAngle(hAxes,viewinfo)

if ~isempty(viewinfo)
    set(hAxes,'CameraViewAngle',viewinfo.CameraViewAngle);
end

%----------------------------------------------------%
function [viewinfo] = localApplyLimits(hAxes,viewinfo)

if ~isempty(viewinfo)
    
names = get(hAxes,'DimensionNames');
for n = names
    if isfield(viewinfo,[n{1} 'Lim']) && isprop(hAxes,[n{1} 'Lim'])
        hAxes.([n{1} 'Lim']) = viewinfo.([n{1} 'Lim']);
        hAxes.([n{1} 'LimMode']) = viewinfo.([n{1} 'LimMode']);
    end
end
end

%----------------------------------------------------%
function [viewinfo] = localApplyViewInfo(hAxes,viewinfo)

if ~isempty(viewinfo)
    matlab.graphics.interaction.internal.restoreViewInteractions(hAxes);
       
    % Reset all properties whose modes were in manual
    viewinfo_properties = {'DataAspectRatio',...
              'CameraViewAngle',...
              'PlotBoxAspectRatio',...
              'CameraPosition',...
              'CameraTarget',...
              'CameraUpVector'};
    axis_properties = {'XLim',...
                    'YLim',...
                    'ZLim'};
    axis_names = {'XAxis',...
                'YAxis',...
                'ZAxis'};
    
    % set all modes back
    for i = 1:numel(viewinfo_properties)
        mode = [viewinfo_properties{i} 'Mode'];
        if (~isfield(viewinfo,mode))
            continue;
        end
        set(hAxes,mode,viewinfo.(mode));
        if strcmpi(viewinfo.(mode),'manual')
            prop = viewinfo_properties{i};
            set(hAxes,prop,viewinfo.(prop))
        end
    end
    if (isfield(viewinfo,'View'))
        set(hAxes,'View',viewinfo.View);
    end
    

    for i = 1:numel(axis_properties) 
        mode = [axis_properties{i} 'Mode'];
        if (~isfield(viewinfo,mode))
            continue;
        end
        set(hAxes,mode,viewinfo.(mode));
        if strcmpi(viewinfo.(mode),'manual')
            current_prop = axis_properties{i};
            saved_limits = viewinfo.(current_prop);
            all_rulers = get(hAxes,axis_names{i});

            if (numel(all_rulers) == 1) 
                all_rulers.Limits = viewinfo.(current_prop);
            else
                for j = 1:numel(all_rulers)
                    all_rulers(j).Limits = saved_limits{j}; 
                end     
            end
        end
    end
end
    
%----------------------------------------------------%
function [viewinfo] = localCreateViewInfo(hAxes)         
% Store axes view state
viewinfo_properties = {'DataAspectRatio',...
              'CameraViewAngle',...
              'PlotBoxAspectRatio',...
              'CameraPosition',...
              'CameraTarget',...
              'CameraUpVector'};
axis_properties = {'XLim',...
                'YLim',...
                'ZLim'};
axis_names = {'XAxis',...
            'YAxis',...
            'ZAxis'};
viewinfo = GetAxesUniqueProperties(hAxes, viewinfo_properties);
viewinfo = GetAxesLimits(hAxes, viewinfo, axis_properties, axis_names);

[az, el] = view(hAxes);
viewinfo.View = [az, el];

%----------------------------------------------------%
function [viewinfo] = GetAxesUniqueProperties(hAxes, propertyList) 
% Save the value of each unique axes property and its mode
for i = 1:numel(propertyList)
    current_prop = propertyList{i};
    current_mode = [propertyList{i} 'Mode'];
    viewinfo.(current_mode) = get(hAxes,current_mode);
    % Only get properties in manual since getting them in auto can trigger
    % an auto-calc
    if strcmp(get(hAxes,current_mode),'manual')
        viewinfo.(current_prop) = get(hAxes,current_prop);
    end
end

%----------------------------------------------------%
function [viewinfo] = GetAxesLimits(hAxes, viewinfo, axis_properties_values, axis_names)
% Save the value of each shared axes property and its mode
for i = 1:numel(axis_names)
    current_mode = [axis_properties_values{i} 'Mode'];
    current_axis = axis_names{i};
    current_axis_property = axis_properties_values{i};
    all_rulers = get(hAxes,current_axis);
    if (numel(all_rulers) > 1)
        viewinfo.(current_mode) = 'manual';
    else
        viewinfo.(current_mode) = get(hAxes,current_mode);
    end
    if strcmp(viewinfo.(current_mode),'manual')
        if (numel(all_rulers) == 1) 
            viewinfo.(current_axis_property) = all_rulers.Limits;
        else
            limits = cell(1,numel(all_rulers));
            for j = 1:numel(all_rulers)
                limits{j} = all_rulers(j).Limits; 
            end
            viewinfo.(current_axis_property) = limits;
        end
    end
end

%----------------------------------------------------%
function [viewinfo] = localViewPropertyInfo(hAxes, KEY)         
% localViewPropertyInfo updates only the View property of an existing
% "viewinfo". This is used by toolboxes, such as Curve Fitting, that want 
% to preserve all property values except for View.

viewinfo = getappdata(hAxes,KEY);
if isempty(viewinfo)
    viewinfo = localCreateViewInfo(hAxes);
else
    [az, el] = view(hAxes);
    viewinfo.View = [az, el];
end

%----------------------------------------------------%
function [viewinfo] = localLimitsInfo(hAxes, KEY)   
% localLimitsInfo  updates only the Limit properties of an existing
% "viewinfo". This is used by toolboxes, such as Curve Fitting, that want
% to preserve all values except for Limits.

viewinfo = getappdata(hAxes,KEY);
names = get(hAxes,'DimensionNames');
axis_properties = {};
axis_names = {};
for n = names
    if isprop(hAxes,[n{1} 'Lim'])
        axis_properties{end+1} = [n{1} 'Lim'];
        axis_names{end+1} = [n{1} 'Axis'];
    end   
end
viewinfo = GetAxesLimits(hAxes, viewinfo, axis_properties, axis_names);
    

%----------------------------------------------------%
function localAuto(hAxes)

% reset 2-D axes
if is2D(hAxes)
   axis(hAxes,'auto');
% reset 3-D axes  
else
   set(hAxes,'CameraViewAngleMode','auto');
   set(hAxes,'CameraTargetMode','auto');
end