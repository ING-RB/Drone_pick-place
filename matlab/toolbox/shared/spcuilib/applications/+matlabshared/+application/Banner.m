classdef Banner < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        ShowMoreInfo = false;
    end
    properties (SetAccess = protected)
        Parent
    end
    
    properties (SetAccess = protected, Hidden)
        Theme
        Messages
        Container = -1;
        Text = -1;
        Button = -1;
        MoreInfo = -1;
        DefaultTextProperties;
        MoreInfoWidth = 0;
    end
    properties (Hidden)
        IsWebFigure = false;
    end
    
    methods
        function this = Banner(hParent)
            this.Parent = hParent;
            if sum(get(ancestor(hParent, 'figure'), 'Color')) < 1
                this.Theme = matlab.graphics.internal.themes.darkTheme;
            else
                this.Theme = matlab.graphics.internal.themes.lightTheme;
            end
        end
        
        function set.ShowMoreInfo(this, newValue)
            this.ShowMoreInfo = newValue;
            update(this);
        end
        
        function addMessage(this, type, message, id, varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.addParameter('MoreInfoText', '');
            p.addParameter('MoreInfoURL', '');
            p.parse(varargin{:});
            
            textOptions = p.Unmatched;
            if ~isempty(p.Results.MoreInfoURL)
                moreInfo = struct('Text', p.Results.MoreInfoURL, 'IsURL', true);
            else
                moreInfo = struct('Text', p.Results.MoreInfoText, 'IsURL', false);
            end
            
            newMessage = struct('type', type, 'message', message, 'identifier', id, ...
                'textOptions', textOptions, 'moreInfo', moreInfo);
            if isempty(this.Messages)
                this.Messages = newMessage;
            else
                this.Messages(end + 1) = newMessage;
            end
            update(this);
        end
        
        function setMessage(this, varargin)
            this.Messages = [];
            addMessage(this, varargin{:});
        end
        
        function removeMessage(this, id)
            m = this.Messages;
            if isempty(m)
                return;
            end
            m(strcmp({m.identifier}, id)) = [];
            this.Messages = m;
            update(this);
        end
        
        function removeAllMessages(this)
            this.Messages = [];
            update(this);
        end
        
        function msg = getMessage(this)
            msg = this.Messages;
            if ~isempty(msg)
                msg = msg(end);
            end
        end
        
        function resize(this)
            c = this.Container;
            if ishghandle(c)
                pos    = getpixelposition(c);
                figPos = getpixelposition(this.Parent);
                pos(3) = figPos(3);
                pos(2) = figPos(4) - pos(4) + 1;
                setpixelposition(c, pos);
            end
        end
        
        function close(this)
            this.Messages(end) = [];
            this.ShowMoreInfo = false;
            update(this);
        end
        
        function delete(this)
            c = this.Container;
            if ishghandle(c)
                delete(c);
            end
        end
    end
    
    methods (Hidden)
        function update(this)
            m = this.Messages;
            c = this.Container;
            if isempty(m)
                if ishghandle(c)
                    delete(c);
                end
            else
                
                m = m(end);
                t = this.Text;
                if ~ishghandle(t)
                    render(this)
                    t = this.Text;
                end
                c = this.Container;
                set(t, this.DefaultTextProperties{:}, m.textOptions);
                
                set(c, 'Visible', 'on');
                pos = getpixelposition(get(c, 'Parent'));
                if strcmp(m(end).type, 'error')
                    color = '--mw-color-error';
                else
                    color = '--mw-color-primary';
                end
                if this.IsWebFigure
                    underScore = '%s';
                else
                    underScore = '<html><u>%s</u></html>';
                end
                if ~this.hasMoreInfo(m) || ~this.ShowMoreInfo
                    txt = m.message;
                    str = sprintf(underScore, getString(message('Spcuilib:application:MoreInfo')));
                else
                    txt = m.moreInfo.Text;
                    str = sprintf(underScore, getString(message('Spcuilib:application:LessInfo')));
                end
                this.MoreInfo.String = str;
                set(t, ...
                    'String', {txt});
                matlab.graphics.internal.themes.specifyThemePropertyMappings(t, ...
                    'ForegroundColor', color);
                ext = t.Extent;

                tpos = getpixelposition(t);

                ext(4) = ceil(ext(3)/tpos(3))*ext(4);
                
                this.MoreInfo.Visible = matlabshared.application.logicalToOnOff(this.hasMoreInfo(m));
                height = max(ext(4)+4, max(22));
                setpixelposition(c, [1 pos(4) - height pos(3) height]);
            end
        end
        
        function render(this)
            f = this.Parent;
            pos = getpixelposition(f);
            
            if matlab.ui.internal.isUIFigure(ancestor(f, 'figure'))
                props = {'AutoResizeChildren', 'off'};
            else
                props = {'Units', 'pixels', ...
                'HighlightColor', get(0, 'DefaultUIPanelShadowColor')};
            end

            this.Container = uipanel(...
                'Parent', f, ...
                'Visible', 'off', ...
                'Tag', 'WarningContainer', ...
                'Position', [pos(1) pos(4)-2 pos(3) 22], ...
                'BorderType', 'Line', ...
                props{:}, ...
                'ResizeFcn', @(~,~)this.protectOnDelete(@this.onContainerResize));
            hText = uicontrol( ...
                'Parent', this.Container, ...
                'Units', 'pixels', ...
                'Tag', 'WarningText', ...
                'Position', [2 1 pos(3) - 20 17], ...
                'HorizontalAlignment', 'left', ...
                'Style', 'text');
            this.MoreInfo = uicontrol( ...
                'Parent', this.Container, ...
                'Units', 'pixels', ...
                'Tag', 'BannerMoreInfoButton', ...
                'Visible', 'off', ...
                'String', getString(message('Spcuilib:application:MoreInfo')), ...
                'Callback', @this.moreInfoCallback);
            this.Button = uicontrol( ...
                'Parent', this.Container, ...
                'Units', 'pixels', ...
                'Tag', 'WarningCloseButton', ...
                'Position', [pos(3) - 21 1 20 19], ...
                'String', 'X', ...
                'Callback', @this.closeCallback);
            import matlab.graphics.internal.themes.specifyThemePropertyMappings;
            specifyThemePropertyMappings(this.Container, ...
                'BackgroundColor', '--mw-backgroundColor-notificationBanner');
            specifyThemePropertyMappings(hText, ...
                'BackgroundColor', '--mw-backgroundColor-notificationBanner');
            specifyThemePropertyMappings(this.MoreInfo, ...
                'BackgroundColor', '--mw-backgroundColor-notificationBanner');
            specifyThemePropertyMappings(this.Button, ...
                'BackgroundColor', '--mw-backgroundColor-notificationBanner');
            
            this.Text = hText;
            this.DefaultTextProperties = {...
                'FontAngle',  hText.FontAngle, ...
                'FontName',   hText.FontName, ...
                'FontSize',   hText.FontSize, ...
                'FontWeight', hText.FontWeight};
            ext = this.MoreInfo.Extent(3);
            this.MoreInfo.String = getString(message('Spcuilib:application:LessInfo'));
            this.MoreInfoWidth = max(ext, this.MoreInfo.Extent(3)) + 20;
        end
        
        function onContainerResize(this)
            %onContainerResize - Resize the text and button when the panel is
            %resized.
            
            pos = getpixelposition(this.Container);
            ext = get(this.Text, 'Extent');
            height = max(pos(4)-6, ext(4)-2);
            pos = [pos(3)-19 -1 20 height + 7];
            setpixelposition(this.Button, pos);
            if hasMoreInfo(this)
                moreWidth = this.MoreInfoWidth;
                pos(1) = pos(1) - moreWidth;
                pos(3) = moreWidth;
                setpixelposition(this.MoreInfo, pos);
            end
            setpixelposition(this.Text, [2 2 pos(1) height]);
            
            update(this);
        end
        
        function closeCallback(this, ~, ~)
            close(this);
        end
        
        function moreInfoCallback(this, ~, ~)
            m = this.Messages(end);
            if this.hasMoreInfo(m) && m.moreInfo.IsURL
                web(m.moreInfo.Text);
            else
                this.ShowMoreInfo = ~this.ShowMoreInfo;
            end
        end
        
        function b = hasMoreInfo(this, m)
            if nargin == 1
                m = this.Messages;
                if isempty(m)
                    b = false;
                else
                    b = this.hasMoreInfo(m(end));
                end
            else
                b = ~isempty(m.moreInfo.Text);
            end
        end
    end

    methods (Access = protected, Hidden)
        function varargout = protectOnDelete(~, fHandle, varargin)
            %protectOnDelete is a wrapper around any callback that protects
            % against deletion of the Banner component while the callback is
            % being processed. Wrap your callback with this method to avoid
            % command line errors being thrown in such circumstances.
            
            try               
                [varargout{1:nargout}] = fHandle(varargin{:});
            catch ME
                if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                    % Do NOT throw error messages on the command line if the
                    % Banner has been deleted while processing a callback.
                    return
                end
                rethrow(ME);
            end
        end
    end
end

% [EOF]
