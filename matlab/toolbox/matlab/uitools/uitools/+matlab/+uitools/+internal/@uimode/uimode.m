classdef uimode < matlab.mixin.SetGetExactNames
    % This function is undocumented and will change in a future release

%uitools.internal.uimode class: This class is the basis of any interactive modes within
% the context of the MATLAB figure window.
%    uitools.uimode methods:
%       calluimode -  Activates a uimode and triggers a callback function with the given object
%       createuimode -  Constructor for the uimode
%       fireActionPostCallback - Execute the ActionPostCallback callback
%       fireActionPreCallback - Execute the ActionPreCallback callback
%       getuimode -  Given the name of a mode, return the mode object, providing it has been
%       modeControl - Prepare and restore the mode state.
%       modeKeyPressFcn -  Modify the window callback function as specified by the mode. Techniques
%       modeWindowButtonDownFcn -  Modify the window callback function as specified by the mode. Techniques
%       modeWindowButtonUpFcn -  Modify the window callback function as specified by the mode. Techniques
%       modeWindowKeyPressFcn -  Modify the window callback function as specified by the mode. Techniques
%       modeWindowKeyReleaseFcn -  Modify the window callback function as specified by the mode. Techniques
%       registerMode -  Register a mode with this mode to be composed.
%       setCallbackFcn -  Modify the window callback function as specified by the mode. Techniques
%       startMode -  Use the Scene Viewer events to delegate to the mode callback functions.
%       unregisterMode -  Given a mode, remove it from the list of modes currently

%   Copyright 2013-2024 The MathWorks, Inc.

properties (AbortSet, SetObservable, GetObservable)
    %Determine whether the mode will take control of the WindowButtonMotionFcn callback
    WindowButtonMotionFcnInterrupt = false; 
    %Determine whether the mode will suspend UICONTROL object callbacks
    UIControlInterrupt = false;
    ShowContextMenu = true;
    
    % A mode may be specified to be a one-shot mode. This means that after a
    % Button-Up event, the mode will be turned off.
    IsOneShot = false; % takes true/false
    UseContextMenu = 'on'; % takes 'on/off' 
    LiveEditorFigure = false;
end

properties (AbortSet, SetObservable, GetObservable, Hidden)
    %Determine whether the mode can be interrupted by another mode
    Blocking = false;
end

properties (Access=protected, Transient, Hidden, AbortSet, SetObservable, GetObservable)
    DeleteListener = []; % Add a delete listener for the purpose of clearing context menus
    FigureDeleteListener = [];% Add a delete listener to the figure.
end

properties (GetAccess=protected, AbortSet, SetObservable, GetObservable, Hidden)
    % Keep a binary flag around to keep track of whether we are busy activating
    % or not.
    BusyActivating = false;
end

properties (SetAccess=protected, AbortSet, SetObservable, GetObservable)
    Name = [];
end

properties (SetAccess=?tmodeWindowButtonDownFcn, Transient)
    FigureHandle = [];
end

properties (SetAccess=protected, Transient, Hidden, AbortSet, SetObservable, GetObservable)
    WindowListenerHandles = []; %Listeners in support of the ButtonDownFilter
    RegisteredModes = []; % Similar to a mode manager, modes may have modes registered with them.
    CurrentMode = []; % A mode can only have one active child mode at a time.
    ModeListenerHandles = [];% Keep a record of listeners on the figure.
end

properties (Transient, AbortSet, SetObservable, GetObservable)
    %  Properties for callback functions
    WindowButtonDownFcn = []; 
    WindowButtonUpFcn = [];
    WindowButtonMotionFcn = [];
    WindowKeyPressFcn = [];
    WindowKeyReleaseFcn = [];
    WindowScrollWheelFcn = [];
    KeyReleaseFcn = [];
    KeyPressFcn = [];
    ModeStartFcn = [];
    ModeStopFcn = [];
    ButtonDownFilter = [];
    UIContextMenu = [];
end

properties (Transient, SetObservable, GetObservable)
    % This property should not use AbortSet because the value of this
    % property includes a struct that may include graphics objects, and
    % comparing the equality of graphics objects can be slow.
    ModeStateData = [];
end

properties (Transient,AbortSet, SetObservable, GetObservable, Hidden)
    UIControlSuspendListener = [];%Add a listener to take care of the UIControl suspension
    UserButtonUpFcn = [];% Caches for the callback functions used during a filtered callback.
    PreviousWindowState = [];
    %Pre and post callback functions
    ActionPreCallback = [];
    ActionPostCallback = [];
    % Hidden Properties that can be inherited
    WindowMotionFcnListener = [];
    FigureState = [];
    % Properties to facilitate mode composition:
    % A mode may have a parent mode if it is being composed.
    ParentMode = [];
    % If a mode is a container mode, it may have a default mode
    DefaultUIMode = '';
end

properties (Transient, AbortSet, SetObservable, Hidden)
    % Holds onto canvas container (figure, uipanel, uitab, etc)
    CanvasContainerHandle = []
end

properties (Transient, Hidden, SetObservable, GetObservable, AbortSet)
   Enable = 'off'; % takes values on/off
end

methods 
    function set.WindowButtonDownFcn(obj,value)
         obj.WindowButtonDownFcn = setCallbackFcn(obj,value,'WindowButtonDownFcn');
    end

    function set.WindowButtonUpFcn(obj,value)
        obj.WindowButtonUpFcn = setCallbackFcn(obj,value,'WindowButtonUpFcn');
    end

    function set.WindowButtonMotionFcn(obj,value)
        obj.WindowButtonMotionFcn = setMotionFcn(obj,value);
    end

    function set.WindowKeyPressFcn(obj,value)
       obj.WindowKeyPressFcn = setCallbackFcn(obj,value,'WindowKeyPressFcn');
    end

    function set.WindowKeyReleaseFcn(obj,value)
        obj.WindowKeyReleaseFcn = setCallbackFcn(obj,value,'WindowKeyReleaseFcn');
    end

    function set.WindowScrollWheelFcn(obj,value)
        obj.WindowScrollWheelFcn = setCallbackFcn(obj,value,'WindowScrollWheelFcn');
    end

    function set.KeyReleaseFcn(obj,value)
        obj.KeyReleaseFcn = setCallbackFcn(obj,value,'KeyReleaseFcn');
    end

    function set.WindowButtonMotionFcnInterrupt(obj,value)
        obj.WindowButtonMotionFcnInterrupt = readOnlyWhileRunning(obj,value,'WindowButtonMotionFcnInterrupt');
    end

    function set.UIControlInterrupt(obj,value)
        obj.UIControlInterrupt = readOnlyWhileRunning(obj,value,'UIControlInterrupt');
    end

    function set.KeyPressFcn(obj,value)
        obj.KeyPressFcn = setCallbackFcn(obj,value,'KeyPressFcn');
    end

    function set.IsOneShot(obj,value)
        obj.IsOneShot = readOnlyWhileRunning(obj,value,'IsOneShot');
    end

    function set.UseContextMenu(obj,value)
        % DataType = 'on/off'
        validatestring(value,{'on','off'},'','UseContextMenu');
        obj.UseContextMenu = value;
    end

    function set.Enable(obj,value)
        % DataType = 'on/off'
        validatestring(value,{'on','off'},'','Enable');
        obj.Enable = modeControl(obj,value);
    end

    function set.ParentMode(obj,value)
        % DataType = 'handle'
        obj.ParentMode = localReparentMode(obj,value);
    end

end   % set and get functions 

methods  %% public methods
    calluimode(hThis,name,callback,obj,evd)
    hThis = createuimode(hThis,hFig,name)
    fireActionPostCallback(hThis,evd)
    fireActionPreCallback(hThis,evd)
    regMode = getuimode(hThis,name)
    newValue = modeControl(hThis,valueProposed)
    modeKeyPressFcn(hMode,hFig,evd,hThis,newKeyPressFcn)
    modeWindowButtonDownFcn(~,hFig,evd,hThis,newButtonDownFcn)
    modeWindowButtonUpFcn(~,hFig,evd,hThis,newButtonUpFcn)
    modeWindowKeyPressFcn(hMode,hFig,evd,hThis,newKeyPressFcn)
    modeWindowKeyReleaseFcn(hMode,hFig,evd,hThis,newKeyUpFcn)
    hMode = registerMode(hThis,hMode)
    newValue = setCallbackFcn(hThis,valueProposed,propToChange)
    startMode(hThis)
    unregisterMode(hThis,hMode)
end  %% public methods 


methods (Hidden) %% possibly private or hidden
    activateuimode(hThis,name)
    adduimode(hThis,hMode)
    flag = hasuimode(hThis,name)
    res = isactiveuimode(hThis,name)
end  %% possibly private or hidden 

methods (Static, Hidden) 
    % Utility method used by modes to detect if the figure is a Live
    % Editor figure. Used primarily to screen out functionality 
    % such as uicontextmenu which is not supported)
    function state = isLiveEditorFigure(hFig)
        state = matlab.internal.editor.figure.FigureUtils.isEditorSnapshotFigure(hFig);
    end
end

end  % classdef


function newValue = localReparentMode(hThis,valueProposed)
% Reparent a mode object

% This property may only be set if the mode is not active
if strcmp(hThis.Enable,'on')
    error(message('MATLAB:uimodes:mode:ReadOnlyWhileRunning', propName));
end

% If the property is empty, we may be unparenting from the figure:
if isempty(hThis.ParentMode)
    hManager = uigetmodemanager(hThis.FigureHandle);
    unregisterMode(hManager,hThis);
else
    unregisterMode(hThis.ParentMode,hThis);
end

newValue = valueProposed;
end  % localReparentMode


%------------------------------------------------------------------------%
function newValue = readOnlyWhileRunning(hThis,valueProposed,propName)
%Enforce the property being read-only while the mode is active

if strcmp(hThis.Enable,'on')
    error(message('MATLAB:uimodes:mode:ReadOnlyWhileRunning', propName));
else
    newValue = valueProposed;
end
end  % readOnlyWhileRunning


%----------------------------------------------------------------------%
function newValue = setMotionFcn(hThis, valueProposed)
% Modify the window callback function as specified by the mode. Techniques
% to minimize mode interaction issues are used here.

newValue = valueProposed;
hThis.WindowMotionFcnListener.Callback = @(obj,evd)(localEvaluateMotionCallback(obj,evd,valueProposed));
end  % setMotionFcn


%----------------------------------------------------------------------%
function localEvaluateMotionCallback(obj,evd,callback)

% Evaluate the callback
hgfeval(callback,obj,evd);
end  % localEvaluateMotionCallback
