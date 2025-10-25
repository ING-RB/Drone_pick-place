classdef UIVideoPreviewer < matlab.ui.componentcontainer.ComponentContainer
    % UIVideoPreviewer a Component Container with an axes to show a preview of
    % a video.
    %
    % matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer(...
    %     "VideoSource", filename)
    % Shows the video specified as filename in the video preview
    %
    % matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer(...
    %     "VideoSource", videoReader)
    % Shows the video specified with the VideoReader object in the video preview
    %
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Dependent = true)
        % The Video Source for the preview, either a file name or a VideoReader
        % object
        VideoSource;
    end
    
    properties (Access = {?UIVideoPreviewer, ?matlab.unittest.TestCase}, Transient, NonCopyable, Hidden)
        Axes matlab.ui.control.UIAxes
        GridLayout matlab.ui.container.GridLayout
        Panel matlab.ui.container.Panel
    end
    
    properties (Access = {?UIAudioPlayer, ?matlab.unittest.TestCase})
        % Current frame in the video preview
        VideoFrame double = 1;
        
        % Approximate number of frames.  For large video files, it can take some
        % time to compute the exact number, but we can do a quick calculation
        % based on the video duration and frames per second.
        ApproxNumFrames double;
        
        % Indices of the frames of the video to show in the preview
        FrameIndices double = [];
        
        % Timer used to update the video preview
        PreviewTimer timer;
        TimerPeriod double = 1;
        
        % Tracks when the mouse is over the preview image or not
        MouseOverAxes logical = false;
        
        % The object used for positioning
        PositionObject = [];
    end
    
    properties(Access = protected, Constant = true)
        NUM_FRAMES_TO_CYCLE = 6;
    end
    
    properties (Access = protected, Transient, NonCopyable)
        VideoSourceI;
        VideoFileNameI;
    end
    
    methods
        function val = get.VideoSource(this)
            % Get the VideoSource property.  If the user set it as a filename,
            % return the filename.  Otherwise return the video player.
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            if ~isempty(this.VideoFileNameI)
                val = this.VideoFileNameI;
            else
                val = this.VideoSourceI;
            end
        end
        
        function set.VideoSource(this, val)
            % Set the VideoSource property, which can be a VideoReader, or a
            % filename.
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
                val
            end
            
            if isa(val, "VideoReader")
                this.VideoSourceI = val;
            elseif strlength(val) > 0
                this.VideoFileNameI = val;
                this.VideoSourceI = VideoReader(val);
            end
            
            if ~isempty(this.VideoSourceI)
                % Compute the approximate number of frames based on the video's
                % duration and frame rate.  This is much, much quicker than
                % accessing the VideoReader.NumFrames value.
                this.ApproxNumFrames = floor(this.VideoSourceI.Duration * this.VideoSourceI.FrameRate);
                this.FrameIndices = [1 (floor(this.ApproxNumFrames/this.NUM_FRAMES_TO_CYCLE)) * (1:(this.NUM_FRAMES_TO_CYCLE-1))];
            end
        end
    end
    
    methods
        function this = UIVideoPreviewer(NameValueArgs)
            % Construct a UIVideoPreviewer
            
            arguments
                NameValueArgs.?matlab.ui.componentcontainer.ComponentContainer
                NameValueArgs.Parent = uifigure
                NameValueArgs.BackgroundColor = [1, 1, 1]
                NameValueArgs.VideoSource = ""
            end
            
            this@matlab.ui.componentcontainer.ComponentContainer(NameValueArgs);
            this.VideoSource = NameValueArgs.VideoSource;
        end
        
        function delete(this)
            % Deletes the UIVideoPreviewer

            if ~isempty(this.PreviewTimer) && isvalid(this.PreviewTimer)
                % stop and delete the timer
                this.stopVideo();
                delete(this.PreviewTimer);
            end
        end
        
        function stop(this)
            % Stops the UIVideoPreviewer image preview that runs on a timer
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            this.stopVideo();
        end
    end
    
    methods (Access = protected)
        function setup(this)
            % Create a uigridlayout for better control over padding, and add an
            % axes to it.
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            this.GridLayout = uigridlayout(this, [1, 1], "Padding", [0, 0, 0, 0]);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(this.GridLayout, ...
                "BackgroundColor", "--mw-graphics-backgroundColor-axes-primary");
            
            this.Axes = uiaxes("Parent", this.GridLayout);
            this.Axes.XAxis.Visible = "off";
            this.Axes.YAxis.Visible = "off";
        end
        
        function update(this)
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            this.setupVideoPreview();
        end
        
        function setupVideoPreview(this)
            % Setup the video preview
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            fig = ancestor(this.Axes, 'figure');
            if isempty(fig.WindowButtonMotionFcn)
                if ~isempty(this.VideoSourceI)
                    % Read the first frame to show in the preview, before the
                    % user hovers over the image
                    frame = this.VideoSourceI.read(1);
                    imagesc(frame, "Parent", this.Axes);
                end
                
                % Try to figure out how to determine the position of the
                % component (to try to track mouse over)
                p = ancestor(this, 'uipanel');
                if isempty(p)
                    this.PositionObject = this;
                else
                    this.PositionObject = p;
                end
                
                fig.WindowButtonMotionFcn = @(es, ed)mouseMotion(this, es, ed);
                
                % Create the preview timer
                this.PreviewTimer = timer(...
                    "TimerFcn", @(~,~)handleUpdateTimer(this), ...
                    "ErrorFcn", @(~,~)handleTimerError(this), ...
                    "Period", this.TimerPeriod, ...
                    "Name", "VideoPreviewTimer", ...
                    "ObjectVisibility", "off", ...
                    "BusyMode", "queue", ...
                    "ExecutionMode", "fixedRate");
            end
            
            % The following code is similar to 'axes image'
            this.Axes.Toolbar.Visible = "off";
            disableDefaultInteractivity(this.Axes);
            set(this.Axes, ...
                "DataAspectRatio", [1 1 1], ...
                "PlotBoxAspectRatioMode", "auto")
            pbarlimit = 0.1;
            
            pbar = get(this.Axes, "PlotBoxAspectRatio");
            pbar = max(pbarlimit, pbar / max(pbar));
            if any(pbar(1:2) == pbarlimit)
                set(this.Axes, "PlotBoxAspectRatio", pbar)
            end
            
            names = get(this.Axes, "DimensionNames");
            set(this.Axes, names{1} + "LimSpec", "tight", names{2} + "LimSpec", "tight");
            set(this.Axes, names{1} + "LimMode", "auto", names{2} + "LimMode", "auto")
        end
        
        function mouseMotion(this, es, ~)
            % Handle mouse motion in the preview component
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
                es
                ~
            end
            
            if ~isvalid(this) ||  ~isvalid(this.PositionObject)
                % This can happen if the window is closing, but the mouse is
                % hovering over the video player -- especially in tests.
                return;
            end

            % Get the current point, and the current position of the component
            pt = es.CurrentPoint;
            pos = this.PositionObject.Position;
            if pt(1) > pos(1) && pt(1) < (pos(1) + pos(3)) && ...
                    pt(2) > pos(2) && pt(2) < (pos(2) + pos(4))
                % The mouse has moved over the component
                if ~this.MouseOverAxes
                    % Start the timer to show the preview frames
                    this.MouseOverAxes = true;
                    start(this.PreviewTimer);
                end
            elseif this.MouseOverAxes
                % The mouse has moved out of the component
                this.MouseOverAxes = false;
                this.stopVideo();
            end
        end
        
        function handleUpdateTimer(this)
            % Handle the preview timer
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            if isvalid(this.Axes) && this.MouseOverAxes
                this.showNextFrame();
            end
        end
        
        function handleTimerError(~)
        end
        
        function showNextFrame(this)
            % Show the next video frame for the preview
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            try
                % Cycle back to the first if needed
                if this.VideoFrame > this.NUM_FRAMES_TO_CYCLE
                    this.VideoFrame = 1;
                end
                
                frame = this.VideoSourceI.read(this.FrameIndices(this.VideoFrame));
                if ~any(frame, 'all')
                    % frame is all black, try a few of the next frames...
                    % maybe this will be better
                    idx = 1;
                    while idx < 20 && ~any(frame, 'all') && ...
                            (this.FrameIndices(this.VideoFrame) + idx < this.ApproxNumFrames)
                        frame = this.VideoSourceI.read(this.FrameIndices(this.VideoFrame) + idx);
                        idx = idx + 2;
                    end
                end
                this.VideoFrame = this.VideoFrame + 1;
                
                % Show the frame image
                imagesc(frame, "Parent", this.Axes);
                drawnow limitrate nocallbacks
            catch
                % Ignore any errors from showing the preview
            end
        end
        
        function stopVideo(this)
            % Stop the video timer which is showing frames of the video
            
            arguments
                this matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer
            end
            
            if ~isempty(this.PreviewTimer) && isvalid(this.PreviewTimer)
                % stop the timer
                stop(this.PreviewTimer);
            end
        end
    end
end
