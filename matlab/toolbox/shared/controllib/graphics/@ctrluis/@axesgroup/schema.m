function schema
% Defines properties for @axesgroup superclass

% Copyright 1986-2020 The MathWorks, Inc.

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'axesgroup');

% General
schema.prop(c,'AxesStyle','handle');              % Axes style parameters (@axesstyle)
schema.prop(c,'EventManager','handle');           % Event coordinator (@eventmgr object)
schema.prop(c,'Grid','on/off');                   % Grid state (on/off)
schema.prop(c,'GridFcn','MATLAB array');          % Grid function (built-in grid if empty)
schema.prop(c,'GridOptions','MATLAB array');      % Grid options (struct)
schema.prop(c,'LabelFcn','MATLAB callback');      % Label building function
p = schema.prop(c,'LayoutManager','on/off');      % Layout manager (on -> uses resize fcn)
p.FactoryValue = 'on';
p = schema.prop(c,'LimitManager','on/off');       % Enable state for limit manager
p.FactoryValue = 'on';
schema.prop(c,'LimitFcn','MATLAB callback');      % Limit picker (ViewChanged callback)
p = schema.prop(c,'NextPlot','string');           % Hold mode [add|replace]
p.FactoryValue = 'replace';     
p = schema.prop(c,'Parent','MATLAB array');                 % Parent figure
p.SetFunction = @localConvertToHandle;
p = schema.prop(c,'Position','MATLAB array');     % Axes group position (in normalized units)
p.AccessFlags.Init = 'off';
schema.prop(c,'Size','MATLAB array');             % Size of axes grid
schema.prop(c,'Title','MATLAB array');            % Title string or cell array(for multiline title)
p = schema.prop(c,'TitleStyle','handle');         % Title style (@labelstyle handle)
p = schema.prop(c,'TitleMode','MATLAB array');        % 'auto' | 'manual'
p.FactoryValue = 'auto';
p = schema.prop(c,'UIContextMenu','MATLAB array');          % Right-click menu root
p.SetFunction = {@localSetFunction,'UIContextMenu'};
schema.prop(c,'Visible','on/off');                % Axis group visibility

% REVISIT: MATLAB array->string vector
% X axis
% Ncol := prod(Size([2 4]))
schema.prop(c,'XLabel','MATLAB array');           % X label (string or cell of length Size(4))
schema.prop(c,'XLabelStyle','handle');            % X label style (@labelstyle handle)
p = schema.prop(c,'XLimMode','MATLAB array');     % X limit mode [auto|manual]
% String vector of length the total number of columns in axis grid
p.SetFunction = {@localSetFunction,'XLimMode'};
p = schema.prop(c,'XLimSharing','string');        % X limit sharing [column|peer|all]
p.FactoryValue = 'column';
p = schema.prop(c,'XScale','MATLAB array');       % X axis scale (Ncol-by-1 string cell)
p.SetFunction = {@localSetFunction,'XScale'};
p = schema.prop(c,'XUnits','MATLAB array');       % X units (string or cell of length Size(4))
p.SetFunction = {@localSetFunction,'XUnits'};
% RE: XUnits covers shared units such as time or frequency units. Use ColumnLabel 
%     to specify column-dependent units (e.g., input units)

% Y axis
% Nrow := prod(Size([2 4]))
schema.prop(c,'YLabel','MATLAB array');           % Y label (string or cell of length Size(3))
schema.prop(c,'YLabelStyle','handle');            % Y label style (@labelstyle handle)
p = schema.prop(c,'YLimMode','MATLAB array');     % Y limit mode [auto|manual]
% String vector of length the total number of rows in axis grid
p.SetFunction = {@localSetFunction,'YLimMode'};
p = schema.prop(c,'YLimSharing','string');        % Y limit sharing [row|peer|all]
p.FactoryValue = 'row';
schema.prop(c,'YNormalization','on/off');         % Y axis normalization
p = schema.prop(c,'YScale','MATLAB array');       % Y axis scale (Nrow-by-1 string cell)
p.SetFunction = {@localSetFunction,'YScale'};
p = schema.prop(c,'YUnits','MATLAB array');       % Y units (string or cell of length Size(3))
p.SetFunction = {@localSetFunction,'YUnits'};
% RE: YUnits covers shared units such as mag or phase units. Use RowLabel 
%     to specify row-dependent units (e.g., output units)
p = schema.prop(c,'CheckForBlankAxes','MATLAB array'); % Flag to indicate if equalizeLims should check for blank axes
p.FactoryValue = false;

% Private properties
p(1) = schema.prop(c,'Axes','MATLAB array');              % Nested @plotarray's
p(2) = schema.prop(c,'Axes2d','MATLAB array');            % Matrix of HG axes handles (virtual)
p(3) = schema.prop(c,'Axes4d','MATLAB array');            % 4D array of HG axes handles (virtual)
p(4) = schema.prop(c,'GridLines','MATLAB array');        % Grid lines
p(4).SetFunction = @localConvertToHandle;
p(5) = schema.prop(c,'MessagePane','MATLAB array');       % Message pane (displayed at top of axesgroup)
set(p,'AccessFlags.PublicGet','off','AccessFlags.PublicSet','off');  
p(5).AccessFlags.Serialize  = 'off';


p = schema.prop(c,'LimitListenersData','MATLAB array');        % ListenerManager Listeners related to limit manager
p = schema.prop(c,'LimitListeners','MATLAB array');        %  Virtual ListenerManager Listeners related to limit manager
p.GetFunction = {@localGetFunction,'LimitListeners'};
set(p,'AccessFlags.PublicGet','on','AccessFlags.PublicSet','off');  

p = schema.prop(c,'ListenersData','MATLAB array');         % ListenerManager
p = schema.prop(c,'Listeners','MATLAB array');         % Virtual ListenerManager
p.GetFunction = {@localGetFunction,'Listeners'};
set(p,'AccessFlags.PublicGet','on','AccessFlags.PublicSet','off', ...
    'AccessFlags.PrivateSet','off');

% Containers for property editor dialog
p(1) = schema.prop(c,'GridContainer','MATLAB array');
p(2) = schema.prop(c,'FontsContainer','MATLAB array');
p(3) = schema.prop(c,'ColorContainer','MATLAB array');
p(4) = schema.prop(c,'LabelsContainer','MATLAB array');
set(p,'AccessFlags.PublicGet','on','AccessFlags.PublicSet','off');  

% Events
schema.event(c,'DataChanged');   % Change in data content (triggers redraw)
schema.event(c,'ViewChanged');   % Change in view content (triggers limit update)
schema.event(c,'PreLimitChanged');   % Issued prior to call to limit picker
schema.event(c,'PostLimitChanged');  % Change in axis limits or scales







