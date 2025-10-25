classdef UIAudioPlayer < matlab.ui.componentcontainer.ComponentContainer
    % UIAudioPlayer a Component Container with an axes to show a preview of
    % an image.
    %
    % matlab.internal.datatools.uicomponents.uiaudioplayer.UIAudioPlayer(...
    %     "AudioSource", filename)
    % Shows the image specified as filename in the image preview
    %
    % matlab.internal.datatools.uicomponents.uiaudioplayer.UIAudioPlayer(...
    %     "AudioSource", filename, "Parent", parentComponent)
    % Shows the image specified as filename in the image preview, which is
    % parented to the parentComponent.
    %
    % matlab.internal.datatools.uicomponents.uiaudioplayer.UIAudioPlayer(...
    %     "AudioSource", data, "SampleRate", fs)
    % Shows the image specified by the cdata in the image preview
    %
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Dependent = true)
        % The Audio Source.  May be a filename or a numeric or logical array
        % representing the audio data.
        AudioSource;
        
        % Sample Rate for the audio data.
        SampleRate;
        
        % Font Properties
        FontAngle;
        FontName;
        FontSize;
        FontUnits;
        FontWeight;
    end
    
    properties (Access = {?UIAudioPlayer, ?matlab.unittest.TestCase}, Transient, NonCopyable, Hidden)
        % The Audio Player consists of an Axes, with a panel which contains the
        % play/pause button, and the stop button
        Axes matlab.ui.control.UIAxes
        GridLayout matlab.ui.container.GridLayout
        Panel matlab.ui.container.Panel
        GridLayout2 matlab.ui.container.GridLayout
        PlayPauseButton matlab.ui.control.Button
        StopButton matlab.ui.control.Button
    end
    
    properties (Access = {?UIAudioPlayer, ?matlab.unittest.TestCase})
        % audioplayer object used to play the audio
        Player;
        
        % Current position in the audio data when playing the audio
        PlayerPosition double = 0;
        
        % Timer used to update a progress indicator as the audio data plays
        PlayerTimer = [];
        TimerPeriod double = 1;
        
        % data indicator line to plot, to indicate the position of the audio
        % when it is playing
        PlayerLine;
    end
    
    properties (Access = protected, Transient, NonCopyable)
        AudioSourceI;
        SampleRateI;
        AudioFileNameI;
    end
    
    properties(Constant = true, Access = {?UIAudioPlayer, ?matlab.unittest.TestCase})
        % Play, Pause and Stop icons
        PLAY_ICON = fullfile(matlabroot, "toolbox", "matlab", "datatools", "media_widgets", "matlab", "+matlab", "+internal", "+datatools", "+uicomponents", "+uiaudioplayer", "images", "Player_Play_24.png");
        PAUSE_ICON = fullfile(matlabroot, "toolbox", "matlab", "datatools", "media_widgets", "matlab", "+matlab", "+internal", "+datatools", "+uicomponents", "+uiaudioplayer", "images", "Player_Pause_24.png");
        STOP_ICON = fullfile(matlabroot, "toolbox", "matlab", "datatools", "media_widgets", "matlab", "+matlab", "+internal", "+datatools", "+uicomponents", "+uiaudioplayer", "images", "Player_Stop_24.png");
        
        % Audio longer than this time will not be playable in MOL
        LONG_AUDIO_TIME = 5;
    end
    
    methods
        function val = get.AudioSource(this)
            % Get the AudioSource property.  If the user set it as a filename,
            % return the filename.  Otherwise return the audio data.
            if ~isempty(this.AudioFileNameI)
                val = this.AudioFileNameI;
            else
                val = this.AudioSourceI;
            end
        end
        
        function set.AudioSource(this, val)
            % Set the AudioSource property, which can be a numeric value, or a
            % filename.
            if isnumeric(val) || islogical(val)
                this.AudioSourceI = val;
            elseif strlength(val) > 0
                % Use audioread to read in the audio file
                [data, fs] = audioread(val);
                
                % Store the data, sample rate, and filename
                this.AudioSourceI = data;
                this.SampleRate = fs;
                this.AudioFileNameI = val;
            end
            
            % Make sure the data is in the expected format (1 or 2 column
            % vectors)
            c = size(this.AudioSourceI, 2);
            if ~isequal(c, 1) && ~isequal(c, 2)
                this.AudioSourceI = this.AudioSourceI';
            end
        end
        
        function val = get.SampleRate(this)
            % Get the SampleRate property
            val = this.SampleRateI;
        end
        
        function set.SampleRate(this, val)
            % Set the SampleRate property
            if ~isempty(val) && (val < 80 || val > 1000000)
                % Apply the same restrictions as audioplayer does
                error(message("MATLAB:datatools:uiaudioplayer:InvalidSampleRate"));
            end
            this.SampleRateI = val;
        end
        
        function val = get.FontAngle(this)
            % Get the FontAngle property
            val = this.Axes.FontAngle;
        end
        
        function set.FontAngle(this, val)
            % Set the FontAngle property
            this.Axes.FontAngle= val;
        end
        
        function val = get.FontName(this)
            % Get the FontName property
            val = this.Axes.FontName;
        end
        
        function set.FontName(this, val)
            % Set the FontName property
            this.Axes.FontName= val;
        end
        
        function val = get.FontSize(this)
            % Get the FontSize property
            val = this.Axes.FontSize;
        end
        
        function set.FontSize(this, val)
            % Set the FontSize property
            this.Axes.FontSize= val;
        end
        
        function val = get.FontUnits(this)
            % Get the FontUnits property
            val = this.Axes.FontUnits;
        end
        
        function set.FontUnits(this, val)
            % Set the FontUnits property
            this.Axes.FontUnits= val;
        end
        
        function val = get.FontWeight(this)
            % Get the FontWeight property
            val = this.Axes.FontWeight;
        end
        
        function set.FontWeight(this, val)
            % Set the FontWeight property
            this.Axes.FontWeight= val;
        end
        
        function this = UIAudioPlayer(NameValueArgs)
            % Construct a UIAudioPlayer
            
            arguments
                NameValueArgs.?matlab.ui.componentcontainer.ComponentContainer
                NameValueArgs.Parent = uifigure
                NameValueArgs.BackgroundColor = [1, 1, 1]
                NameValueArgs.AudioSource = ""
                NameValueArgs.SampleRate = []
            end
            
            this@matlab.ui.componentcontainer.ComponentContainer(NameValueArgs);
            this.AudioSource = NameValueArgs.AudioSource;
        end
        
        function delete(this)
            % Deletes the UIAudioPlayer
            
            if ~isempty(this.PlayerTimer) && isvalid(this.PlayerTimer)
                % stop and delete the progress timer first, in case it is about
                % to fire
                stop(this.PlayerTimer);
                delete(this.PlayerTimer);
            end
            
            if ~isempty(this.Player) && isvalid(this.Player)
                % Delete the audioplayer object
                delete(this.Player);
            end
        end
        
        function stop(this)
            % Stops the UIAudioPlayer audio play-through that may be running
            
            arguments
                this matlab.internal.datatools.uicomponents.uiaudioplayer.UIAudioPlayer
            end
            
            this.stopAudio();
        end
    end
    
    methods (Access = protected)
        function setup(this)
            % Create a uigridlayout for better control over padding, and add an
            % axes to it.
            this.GridLayout = uigridlayout(this, [2, 1], "Padding", [0, 0, 0, 0]);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(this.GridLayout, ...
                "BackgroundColor", "--mw-graphics-backgroundColor-axes-primary");
            this.GridLayout.ColumnWidth = {'1x'};
            this.GridLayout.RowHeight = {'1x', 40};
            
            this.Axes = uiaxes("Parent", this.GridLayout);
            this.Axes.Layout.Row = 1;
            this.Axes.Layout.Column = 1;
            
            this.Panel = uipanel(this.GridLayout);
            this.Panel.Layout.Row = 2;
            this.Panel.Layout.Column = 1;
            
            % Create GridLayout2
            this.GridLayout2 = uigridlayout(this.Panel);
            this.GridLayout2.ColumnWidth = {'1x', 24, 24, '1x'};
            this.GridLayout2.RowHeight = {24};
            this.GridLayout2.Padding = [10 8 10 8];
            
            % Create PlayPauseButton
            this.PlayPauseButton = uibutton(this.GridLayout2, "push");
            this.PlayPauseButton.Layout.Row = 1;
            this.PlayPauseButton.Layout.Column = 2;
            this.PlayPauseButton.Text = ""; %"Play";
            this.PlayPauseButton.Icon = this.PLAY_ICON;
            this.PlayPauseButton.ButtonPushedFcn = @this.playPauseButtonPushed;
            
            % Create StopButton
            this.StopButton = uibutton(this.GridLayout2, "push");
            this.StopButton.Layout.Row = 1;
            this.StopButton.Layout.Column = 3;
            this.StopButton.Text = ""; %s"Stop";
            this.StopButton.Icon = this.STOP_ICON;
            this.StopButton.ButtonPushedFcn = @this.stopButtonPushed;
        end
        
        function update(this)
            this.setupAudioPlayer();
        end
        
        function setupAudioPlayer(this)
            % Plot the audio data in the axes
            if isempty(this.Axes.Children)
                line(1:length(this.AudioSourceI), this.AudioSourceI(:,1), "Parent", this.Axes);

                if size(this.AudioSource, 2) == 2
                    % Plot the 2nd line if there are two audio channels
                    line(1:length(this.AudioSourceI), this.AudioSourceI(:,2), "Parent", this.Axes);
                end
            end
            if ~isempty(this.SampleRate)
                % Only update ticks if we have a valid audio source (the sample
                % rate is set)
                ticks = this.Axes.XTick;
                numTicks = length(ticks);
                if numTicks > 5
                    % Limit the number of ticks if there's more than an arbitrary
                    % amount (5)
                    t = nan(1, floor(numTicks/2) + 1);
                    newTickIdx = 1;
                    for idx = 1:2:numTicks
                        t(newTickIdx) = ticks(idx);
                        newTickIdx = newTickIdx + 1;
                    end
                    this.Axes.XTick = rmmissing(t);
                end

                % Show the tick labels as durations in seconds, starting at 0
                this.Axes.XTickLabel = string(duration(0, 0, this.Axes.XTick/this.SampleRate));
                this.Axes.XTickLabel{1} = '';
            end
            this.Axes.XAxisLocation = "top";
            this.Axes.Toolbar.Visible = "off";
            disableDefaultInteractivity(this.Axes);
            
            this.setPlayEnabledForLength();
        end
        
        function t = getTypeName(~)
            t = 'uiaudioplayer';
        end
        
        function groups = getPropertyGroups(~)
            groups(1) = matlab.mixin.util.PropertyGroup(...
                {'AudioSource', 'SampleRate', 'Position'});
        end
    end
    
    methods(Access = {?UIAudioPlayer, ?matlab.unittest.TestCase})
        function playPauseButtonPushed(this, btn, ~)
            if strcmp(btn.Icon, this.PLAY_ICON)
                % The user clicked on the 'Play' icon on the button
                if isempty(this.Player)
                    % Create the audioplayer for the audio source data and
                    % sample rate, and play it
                    this.Player = this.createAudioPlayer();
                    if isempty(this.Player)
                        % Unable to create the audioplayer.  Disable the
                        % buttons, and just return.  (This is most likely to
                        % happen in the connector workflow)
                        this.disablePlayFunctionality();
                        return;
                    end
                    this.Player.play();
                else
                    % The player was already created, so just resume from where
                    % it was.
                    this.Player.resume();
                end
                btn.Icon = this.PAUSE_ICON;
                if ~isempty(this.PlayerLine)
                    delete(this.PlayerLine);
                end
                
                % Create the line to show the progress indicator as the audio
                % plays, and start the timer
                this.PlayerLine = animatedline(this.Axes, "LineStyle", "-", "LineWidth", 0.25, "Color", "#A9A9A9");
                this.PlayerTimer = timer(...
                    "TimerFcn", @(~,~)handleUpdateTimer(this), ...
                    "ErrorFcn", @(~,~)handleTimerError(this), ...
                    "Period", this.TimerPeriod, ...
                    "Name", "AudioPlayerTimer", ...
                    "ObjectVisibility", "off", ...
                    "BusyMode", "queue", ...
                    "ExecutionMode", "fixedRate");
                start(this.PlayerTimer)
            else
                % The user clicked on the 'Pause' button, so pause playing and
                % stop the timer
                btn.Icon = this.PLAY_ICON;
                this.Player.pause();
                
                stop(this.PlayerTimer);
            end
        end
        
        function player = createAudioPlayer(this)
            % Create the audioplayer object for the current audio source.
            % Returns [] if it could not be created.
            
            arguments
                this matlab.internal.datatools.uicomponents.uiaudioplayer.UIAudioPlayer
            end
            
            % The audio player warns if it could not be created, change this to
            % an error temporarily so it can be caught.
            ws = warning;
            cl = onCleanup(@() warning(ws));
            warning('error', 'MATLAB:audiovideo:audioplayer:noAudioOutputDevice');
            try
                player = audioplayer(this.AudioSourceI, this.SampleRate);
            catch
                % The player couldn't be created
                player = [];
            end
        end
        
        function stopButtonPushed(this, ~, ~)
            % Stop the audio, remove the indicator line
            this.stopAudio();
        end
        
        function handleUpdateTimer(this)
            currPosition = this.Player.CurrentSample;
            if currPosition == 1 && this.PlayerPosition > 1
                % The audio player's position goes back to 1 when it is
                % complete.  When this happens, treat this as if the stop button
                % was pushed.
                this.stopButtonPushed();
                this.PlayerPosition = currPosition;
            else
                this.PlayerPosition = currPosition;
                
                % Update the indicator line to show the progress
                ylim = this.Axes.YLim;
                yvals = ylim; %ylim(1):0.1:ylim(2);
                clearpoints(this.PlayerLine);
                addpoints(this.PlayerLine, repmat(this.PlayerPosition, length(yvals), 1), yvals);
                drawnow limitrate nocallbacks
            end
        end
        
        function handleTimerError(~)
        end
        
        function stopAudio(this)
            % Stop the audio, stop the timer, and remove the progress indicator
            % line
            if ~isempty(this.Player)
                stop(this.PlayerTimer);
                this.Player.stop();
                delete(this.Player);
                this.Player = [];
                this.PlayPauseButton.Icon = this.PLAY_ICON;
                this.PlayerPosition = 0;
            end
            
            if ~isempty(this.PlayerLine) && isvalid(this.PlayerLine)
                delete(this.PlayerLine);
            end
        end
        
        function setPlayEnabledForLength(this)
            % Disable the play button in MOL for long audio files
            import matlab.internal.capability.Capability;
            if ~Capability.isSupported(Capability.LocalClient) && ...
                    length(this.AudioSourceI)/this.SampleRate > this.LONG_AUDIO_TIME
                this.disablePlayFunctionality();
                tt = getString(message("MATLAB:datatools:importdata:AudioTooLong"));
                this.PlayPauseButton.Tooltip = tt;
                this.StopButton.Tooltip = tt;
            end
        end
        
        function disablePlayFunctionality(this)
            % Disable the play/pause and stop buttons
            this.PlayPauseButton.Enable = "off";
            this.StopButton.Enable = "off";
        end
    end
end
