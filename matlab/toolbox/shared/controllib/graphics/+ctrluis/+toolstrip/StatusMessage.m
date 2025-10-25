classdef StatusMessage <handle
    % Class for putting status messages in the Desktop frame's status bar.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    properties
        ParentTool = 'pidtuner'
        Version = 1
    end
    properties (SetAccess = protected)
        Frame
        StatusBar
        
        EastMessage = ''
        EastIcon
        EastLabel
        EastPanel
        EastIconType
        
        WestMessage = ''
        WestIcon
        WestLabel
        WestPanel
        WestIconType
        
        ProgressBar
    end
    
    methods
        function this = StatusMessage(Frame,varargin)
            % Constructor.
            % Frame: name of the frame (e.g., "PID Tuner")
            if nargin<1
                return
            elseif nargin>1.5
                this.Version = varargin{1};
            end
            
            % Version 1 = Java based rendering
            % Version 2 = Javascript based rendering
            if this.Version == 1
                
            else
                % Create Status Bar
                this.Frame = Frame;
                this.StatusBar = matlab.ui.internal.statusbar.StatusBar;
                this.StatusBar.Tag = strcat(Frame,'StatusBar');     % App can replace this tag
                
                % Create left side status group
                this.WestPanel = matlab.ui.internal.statusbar.StatusGroup;
                this.WestPanel.Tag = strcat(Frame,':WestPanel');
                this.WestPanel.Region = 'left'; % This is not required but is here for clarity
                
                % Create right side status group
                this.EastPanel = matlab.ui.internal.statusbar.StatusGroup;
                this.EastPanel.Tag = strcat(Frame,':EastPanel');
                this.EastPanel.Region = 'right';
                
                % Create left side label
                this.WestLabel = matlab.ui.internal.statusbar.StatusLabel;
                this.WestLabel.Tag = strcat(Frame,':WestLabel');
                this.WestPanel.add(this.WestLabel);
                
                % Create right side label
                this.EastLabel = matlab.ui.internal.statusbar.StatusLabel;
                this.EastLabel.Tag = strcat(Frame,':EastLabel');
                this.EastPanel.add(this.EastLabel);                
                
                % Progress Bar
                this.ProgressBar = matlab.ui.internal.statusbar.StatusProgressBar;
                this.ProgressBar.Tag = strcat(Frame, 'StatusProgressBar');
                
                % Add Left and Right side panels to StatusBar
                this.StatusBar.add(this.WestPanel);
                this.StatusBar.add(this.EastPanel);
            end
        end
        
        function setText(this, Text, IconType, Location)
            % Add message to status bar.
            % Text: string
            % Icon: a name or []
            %     Supported names are: 'info', 'warning', 'error'
            %     [] means no icon
            % Location: one of: 'east', or 'west'
            %
            % Do not use Text = '' to empty out contents; use the "reset"
            % method instead.
           
            Icon = [];           

            if this.Version == 1

            else
                switch lower(Location)
                    case 'east'
                        this.EastMessage = Text;
                        this.EastIcon = [];
                        this.EastIconType = IconType;
                        
                        % Add text and icon to label
                        this.EastLabel.Text = Text;
                        this.EastLabel.Icon = Icon;
                        
                    case 'west'
                        this.WestMessage = Text;
                        this.WestIcon = [];
                        this.WestIconType = IconType;
                        
                        % Add text and icon to label
                        this.WestLabel.Text = Text;
                        this.WestLabel.Icon = Icon;
                end
            end
        end
        
        function reset(this)
            % Remove all messages
            if this.Version == 1

            else
                if ~isempty(this.WestMessage)
                    setText(this, '', [], 'west')
                end

                if ~isempty(this.EastMessage)
                    setText(this, '', [], 'east')
                end
                
                % Hide Progress Bar
                this.ProgressBar.Indeterminate = false;
                % Only remove if Progressbar is already added
                if ~isempty(this.EastPanel.contains('StatusProgressBar'))
                    this.EastPanel.remove(this.ProgressBar);
                end
            end
        end
        
        function showWaitBar(this, Message)
            % Show indefinite waitbar on the right corner.
            if this.Version == 1

            else
               this.ProgressBar.Indeterminate = true;
               % Only remove if Progressbar is not already added
               if isempty(this.EastPanel.contains('StatusProgressBar'))
                    this.EastPanel.add(this.ProgressBar);
               end
            end
             setText(this, [Message ' '], [], 'east');
        end
        
        function hideWaitBar(this)
            % Hide waitbar on the right corner.
            if this.Version == 1

            else
                this.ProgressBar.Indeterminate = false;
                % Only remove if Progressbar is already added
                if ~isempty(this.EastPanel.contains('StatusProgressBar'))
                    this.EastPanel.remove(this.ProgressBar);
                end
            end
            setText(this, '', [], 'east');
        end
        function val = isWestMessageClear(this)
            val = isempty(this.WestMessage);
        end
        function val = isEastMessageClear(this)
            val = isempty(this.EastMessage);
        end
        function out = isWestMessageText(this, val)
            out = false;
            for i = 1:length(val)
                out = out || strcmp(this.WestMessage, val{i});
            end
        end
    end
end
