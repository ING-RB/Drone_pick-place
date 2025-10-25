classdef SliderView < handle & ...
        robotics.appscore.internal.mixin.MsgCatalogHelper & ...
        robotics.appscore.internal.mixin.CallbackDebugHelper
    %This class is for internal use only. It may be removed in the future.

    %SLIDERVIEW View portion of the slider in MVC design pattern.

    %   Copyright 2018-2023 The MathWorks, Inc.


    properties (Constant)
        %DefaultContainerHeight
        DefaultContainerHeight = 60; % in pixels

        %DefaultStepperButtonLeftBottom
        DefaultStepperButtonLeftBottom = [10 10]; % in pixels w.r.t. container

        %DefaultIconButtonSize
        DefaultIconButtonSize = [24 24]; % in pixels

        %DefaultEditLength
        DefaultEditLength = 80; % in pixels

        %DefaultBottomTrackColor
        DefaultBottomTrackColor = "--mw-backgroundColor-primary"; % very light gray

        %DefaultMiddleTrackColor
        DefaultMiddleTrackColor = "--mw-backgroundColor-searchHighlight-tertiary"; % orange

        %DefaultTopTrackColor
        DefaultTopTrackColor = "--mw-graphics-colorNeutral-region-primary"; % gray

        %DefaultScrubberColor
        DefaultScrubberColor = "--mw-graphics-colorOrder-5-secondary";% light green


        %DefaultTrackHeight
        DefaultTrackHeight = 10; % in pixels

        %DefaultSliderLeftBottom
        DefaultSliderLeftBottom = [10 45]; % in pixels w.r.t. container

        %DefaultScrubberWidth
        DefaultScrubberWidth = 10; % in pixels

        %DefaultScrubberVerticalMargin
        DefaultScrubberVerticalMargin = 2; % in pixels

        %DefaultScrubberBorderWidth
        DefaultScrubberBorderWidth = 1; % in pixels
    end


    events
    %SliderView_CurrentValueEditChanged
    SliderView_CurrentValueEditChanged

    %SliderView_BackwardStepperClicked
    SliderView_BackwardStepperClicked

    %SliderView_ForwardStepperClicked
    SliderView_ForwardStepperClicked

    %SliderView_ScrubberReleased
    SliderView_ScrubberReleased

    %SliderView_ScrubberDragged
    SliderView_ScrubberDragged

    %SliderView_RefreshRequested
    SliderView_RefreshRequested
end

properties

    %Figure Parent of the slider widget.
    %   The Units property of figure must be set to 'pixels'
    Figure

    %ContainerPanel
    ContainerPanel

    %SliderPanel
    SliderPanel

    %BottomTrack
    BottomTrack

    %MiddleTrack
    MiddleTrack

    %TopTrack
    TopTrack

    %Scrubber
    Scrubber

    %ForwardStepper
    ForwardStepper

    %BackwardStepper
    BackwardStepper

    %CurrentValueEdit
    CurrentValueEdit

    %MaxValueEdit
    MaxValueEdit

    %IconDir
    IconDir
end


properties
    %Tag
    Tag
end

properties
    %WindowMouseReleaseListener
    WindowMouseReleaseListener

    %WindowMouseMotionListener
    WindowMouseMotionListener
end



methods
    function obj = SliderView(fig, tag)
    %SLIDER Constructor
        obj.Tag = tag;
        obj.CallbackDebug = false;
        obj.MsgIDPrefix = 'shared_robotics:robotappscore:slider';
        assert(isa(fig, 'matlab.ui.Figure') && isvalid(fig) && strcmp(fig.Units, 'pixels'));
        obj.Figure = fig;

        figPos = getpixelposition(obj.Figure);
        params.Position = [1 1 figPos(3) obj.DefaultContainerHeight];
        obj.ContainerPanel = createPanel(obj.Figure, [obj.Tag '_SliderContainer'], params);

        params.BorderType = 'None';
        params.Position = getpixelposition(obj.ContainerPanel);
        obj.SliderPanel = createPanel(obj.ContainerPanel, [obj.Tag '_Slider'], params);

        obj.IconDir = fullfile(matlabroot, 'toolbox', 'shared', 'robotics', 'robotappscore', 'icons');

        createDefaultLayout(obj);

        % HG callbacks
        obj.setCallBacks();

        % do no use SizeChangedFcn here
        addlistener(obj.Figure, 'SizeChanged', @(src, evt) obj.onSizeChangedCallback(src, evt));

    end

end

methods (Access = protected)

    function createDefaultLayout(obj)
    %createDefaultLayout

    % the sequence of panel initialization matters
        refPosition = obj.SliderPanel.InnerPosition;
        trackLength = refPosition(3)-2*obj.DefaultSliderLeftBottom(1);

        % default bottom track
        params.BackgroundColor = obj.DefaultBottomTrackColor;
        params.Position = [obj.DefaultSliderLeftBottom(1), ...
                           obj.DefaultSliderLeftBottom(2), ...
                           trackLength, obj.DefaultTrackHeight];
        obj.BottomTrack = createPanel(obj.SliderPanel, ...
                                      [obj.Tag '_BottomTrack'], params);

        % default middle track
        params.BackgroundColor = obj.DefaultMiddleTrackColor;
        params.Position = [obj.DefaultSliderLeftBottom(1), ...
                           obj.DefaultSliderLeftBottom(2), ...
                           trackLength, obj.DefaultTrackHeight];
        obj.MiddleTrack = createPanel(obj.SliderPanel, ...
                                      [obj.Tag '_MiddleTrack'], params);

        % default top track
        params.BackgroundColor = obj.DefaultTopTrackColor;
        params.Position = [obj.DefaultSliderLeftBottom(1), ...
                           obj.DefaultSliderLeftBottom(2), ...
                           trackLength, obj.DefaultTrackHeight];
        obj.TopTrack = createPanel(obj.SliderPanel, ...
                                   [obj.Tag '_TopTrack'], params);

        % default scrubber
        params.BackgroundColor = obj.DefaultScrubberColor;
        pos = getpixelposition(obj.TopTrack);
        params.Position = [pos(1)- 0.5*obj.DefaultScrubberWidth, ...
                           pos(2)-obj.DefaultScrubberVerticalMargin, ...
                           obj.DefaultScrubberWidth, ...
                           pos(4)+2*obj.DefaultScrubberVerticalMargin];
        params.BorderWidth = obj.DefaultScrubberBorderWidth;
        obj.Scrubber = createPanel(obj.SliderPanel, ...
                                   [obj.Tag '_Scrubber'], params);

        % default backward stepper
        params = [];
        vSpace1 = 5;
        ibSize = obj.DefaultIconButtonSize;
        params.Position = [obj.DefaultStepperButtonLeftBottom(1), ...
                           obj.DefaultStepperButtonLeftBottom(2), ...
                           ibSize(1), ibSize(2)];
        params.BackgroundColor = "--mw-backgroundColor-primary";
        params.Enable = 'on';
        params.TooltipString = obj.retrieveMsg('BackwardStepperDescription');
        params.IconAlignment = 'leftmargin';
        obj.BackwardStepper = createIconButton(obj.ContainerPanel, [obj.Tag '_BackwardStepper'], params, 'stepBackwardUI', ibSize);

        params.Position = [obj.DefaultStepperButtonLeftBottom(1)+ibSize(1)+vSpace1, ...
                           obj.DefaultStepperButtonLeftBottom(2), ...
                           ibSize(1), ibSize(2)];
        params.IconAlignment = 'rightmargin';
        params.TooltipString = obj.retrieveMsg('ForwardStepperDescription');
        obj.ForwardStepper = createIconButton(obj.ContainerPanel, [obj.Tag '_ForwardStepper'], params, 'stepForwardUI', ibSize);


        % default current scan text box
        params = [];
        vSpace2 = 15;
        params.Position = [obj.DefaultStepperButtonLeftBottom(1)+2*ibSize(1)+vSpace2, ...
                           obj.DefaultStepperButtonLeftBottom(2), ...
                           obj.DefaultEditLength, ibSize(2)];
        params.Enable = 'on';
        params.TooltipString = obj.retrieveMsg('CurrentScanEditDescription');
        params.String = 1;

        obj.CurrentValueEdit = createEdit(obj.ContainerPanel, ...
                                          [obj.Tag '_CurrentScanEdit'], params);

        delimiterLabelWidth = 15;
        % default total scans text box
        params.Position = [obj.DefaultStepperButtonLeftBottom(1) + 2*ibSize(1) + obj.DefaultEditLength + vSpace2 + delimiterLabelWidth, ...
                           obj.DefaultStepperButtonLeftBottom(2), ...
                           obj.DefaultEditLength, ibSize(2)];
        params.Enable = 'off';
        params.TooltipString = obj.retrieveMsg('TotalScansEditDescription');
        params.String = 1;
        obj.MaxValueEdit = createEdit(obj.ContainerPanel, ...
                                      [obj.Tag '_TotalScansEdit'], params);


        % default delimiter (/)
        params = [];
        params.String = '/';
        params.BackgroundColor = "--mw-backgroundColor-primary";
        params.Position = [obj.DefaultStepperButtonLeftBottom(1) + 2*ibSize(1) + vSpace2 + obj.DefaultEditLength, ...
                           obj.DefaultStepperButtonLeftBottom(2), ...
                           delimiterLabelWidth, ibSize(2)];
        createLabel(obj.ContainerPanel, params);

    end



%% slider internal callbacks
function onSizeChangedCallback(obj, source, event)
%onSizeChangedCallback Callback function when SizeChanged event is fired
    obj.echo(source, event);

    pos = source.Position;

    obj.SliderPanel.Position(3) =  pos(3);
    obj.ContainerPanel.Position(3) = pos(3);

    updateTrackLengths(obj, pos(3));
    obj.notify('SliderView_RefreshRequested');
end

function scrubberButtonDownCallback(obj, source, event)
%scrubberButtonDownCallback
    obj.echo(source, event);

    if ~isempty(obj.WindowMouseMotionListener) && isvalid(obj.WindowMouseMotionListener)
        delete(obj.WindowMouseMotionListener);
        delete(obj.WindowMouseReleaseListener);
    end

    % % cannot use listener on WindowMouseMotion event, as CurrentPoint will not be updated
    % obj.Figure.WindowButtonMotionFcn = @obj.windowMouseMotionCallback;

    obj.WindowMouseMotionListener = addlistener(obj.Figure, 'WindowMouseMotion', @obj.windowMouseMotionCallback);
    obj.WindowMouseReleaseListener = addlistener(obj.Figure, 'WindowMouseRelease', @obj.windowMouseReleaseCallback);

end

function windowMouseMotionCallback(obj, source, event)
%windowMouseMotionCallback
    obj.echo(source, event);

    %posMouse = obj.Figure.CurrentPoint;
    posMouse = event.Point;
    px = posMouse(1); % this location should be a point inside scrubber

    scrubberWid = obj.Scrubber.Position(3);

    if px < obj.BottomTrack.Position(1)
        px = obj.BottomTrack.Position(1);
    end
    if px > obj.BottomTrack.Position(1) + obj.BottomTrack.Position(3)
        px = obj.BottomTrack.Position(1) + obj.BottomTrack.Position(3);
    end

    obj.Scrubber.Position(1) = px - 0.5*scrubberWid;

    import robotics.appscore.internal.eventdata.*
    obj.notify('SliderView_ScrubberDragged', SliderScrubberEventData(px));

end

function windowMouseReleaseCallback(obj, source, event)
%windowMouseReleaseCallback
    obj.echo(source, event);

    % clear callbacks/listeners
    %obj.Figure.WindowButtonMotionFcn = [];
    delete(obj.WindowMouseMotionListener);
    delete(obj.WindowMouseReleaseListener);

    obj.notify('SliderView_ScrubberReleased');
end

function backwardStepperButtonDownCallback(obj, source, event)
%backwardStepperButtonDownCallback
    obj.echo(source, event);
    obj.notify('SliderView_BackwardStepperClicked');
end

function forwardStepperButtonDownCallback(obj, source, event)
%forwardStepperButtonDownCallback
    obj.echo(source, event);
    obj.notify('SliderView_ForwardStepperClicked');
end

function currentValueEditChangedCallback(obj, source, event)
%currentValueEditChangedCallback
    obj.echo(source, event);

    v = str2double(source.Value);
    import robotics.appscore.internal.eventdata.*
    obj.notify('SliderView_CurrentValueEditChanged', VectorEventData(v));
end

function setCallBacks(obj)
%setCallBacks
    obj.CurrentValueEdit.ValueChangedFcn = @(src, evt) obj.currentValueEditChangedCallback(src, evt);
    obj.BackwardStepper.ButtonPushedFcn = @obj.backwardStepperButtonDownCallback;
    obj.ForwardStepper.ButtonPushedFcn = @obj.forwardStepperButtonDownCallback;
    obj.Scrubber.ButtonDownFcn = @(src, evt) obj.scrubberButtonDownCallback(src, evt);
end


    end

    methods

        function refresh(obj, data)
            %refresh Refresh the composite slider widget so that the display
            %   is consistent with the model data
            xb = obj.BottomTrack.Position(1);
            lb = obj.BottomTrack.Position(3);

            % refresh min max value edit fields
            updateEdit(obj.CurrentValueEdit,num2str(data.CurrentValue));
            updateEdit(obj.MaxValueEdit,num2str(data.MaxValue));

            % refresh top track to reflect current MaxAllowedValue
            xtNew = data.MaxAllowedValuePixels + xb;
            ltNew = max(0, xb + lb - xtNew);
            obj.TopTrack.Position = [xtNew, obj.TopTrack.Position(2), ...
                                        ltNew, obj.TopTrack.Position(4)];

            % refresh middle track to reflect current SyncStartValue
            xmNew = data.SyncStartValuePixels + xb;
            lmNew = max(0, xb + lb - xmNew);
            obj.MiddleTrack.Position = [xmNew, obj.MiddleTrack.Position(2), ...
                                        lmNew, obj.MiddleTrack.Position(4)];

            % refresh scrubber position to reflect CurrentValue
            scrubberWid = obj.Scrubber.Position(3);
            obj.Scrubber.Position(1) = data.CurrentValuePixels + xb - 0.5*scrubberWid;
        end

        function freeze(obj)
            %freeze
            obj.Scrubber.Visible = 'off';
            obj.BackwardStepper.Enable = 'off';
            obj.ForwardStepper.Enable = 'off';
            obj.CurrentValueEdit.Enable = 'off';
        end

        function thaw(obj)
            %thaw
            obj.Scrubber.Visible = 'on';
            obj.BackwardStepper.Enable = 'on';
            obj.ForwardStepper.Enable = 'on';
            obj.CurrentValueEdit.Enable = 'on';
        end
    end


    methods (Access = protected)
         %% helpers
        function updateTrackLengths(obj, width)
            %updateTrackLengths
            posB = obj.BottomTrack.Position;
            posM = obj.MiddleTrack.Position;
            posT = obj.TopTrack.Position;
            if width > 2*posB(1)
                posB(3) = width-2*posB(1);
                obj.BottomTrack.Position = posB;
                obj.MiddleTrack.Position = rescaleTrackLength(posM, posB(3), posB(1:2));
                obj.TopTrack.Position = rescaleTrackLength(posT, posB(3), posB(1:2));
            end
        end

    end
end


%% gui utilities
function posNew = rescaleTrackLength(origPos, newTrackLength, leftBottomCorner)
    %rescaleTrackLength
    x1 = origPos(1);
    l1 = origPos(3);

    xb = leftBottomCorner(1);

    x1New = newTrackLength/(x1 - xb + l1)*(x1 -xb) + xb;
    l1New = newTrackLength + xb - x1New;

    posNew = [x1New, origPos(2), max(l1New, 0), max(origPos(4), 0)];
end


function hPanel = createPanel(parent, tag, params)
    %createPanel Create a uipanel object with user customization
    %   parent should also be a uipanel object
    
    % defaults
    backgroundColor = "--mw-backgroundColor-primary";
    borderType = 'line';
    units = 'pixels';
    position = [0, 0, 10, 10];
    
    % optional user inputs
    if nargin > 2
        if isfield(params, 'BackgroundColor')
            backgroundColor = params.BackgroundColor;
        end
        if isfield(params, 'BorderType')
            borderType = params.BorderType;
        end
        if isfield(params, 'Position')
            position = params.Position;
        end
        if isfield(params, 'Units')
            units = params.Units;
        end
    end
    
    % create the customized panel
    hPanel = uipanel('parent', parent,...
        'Units', units,...
        'Tag', tag, ...
        ... 'BackgroundColor', backgroundColor,...
        ...'BorderWidth', borderWidth,...
        'Position', position,...
        'BorderType', borderType,...
        ...'HighlightColor', highlightColor,...
        'Visible', 'on');
    hPanel.AutoResizeChildren = 'off';
    matlab.graphics.internal.themes.specifyThemePropertyMappings(hPanel,"BackgroundColor",backgroundColor);
end

function hEdit = createEdit(parent, tag, params)
    %createEditBox
    hEdit = uieditfield(parent, 'text', ...
        'Tag', tag, ...
        'position', params.Position, ...
        'Enable', params.Enable);
end

function hLabel = createLabel(parent, params)
    %createLabel Static text
    hLabel = uilabel(parent,'position', params.Position, ...
        ...'BackgroundColor', params.BackgroundColor,  ...
        'FontSize', 15, ...
        'Text', params.String);
    matlab.graphics.internal.themes.specifyThemePropertyMappings(hLabel,"BackgroundColor",params.BackgroundColor);
end

function updateEdit(hEdit, str) 
	%updateEdit
	
	hEdit.Value = str;
end

function hButton = createIconButton(varargin)
    %createIconButton button with icon
    hButton = robotics.appscore.internal.createIconButton(varargin{:});
end
