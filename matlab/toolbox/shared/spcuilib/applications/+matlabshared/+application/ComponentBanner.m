classdef ComponentBanner < handle
    %ComponentBanner
    % Add banner functionality to an object.  This requires Figure and
    % Layout are both protected or public properties.
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        Banner
        CurrentObjectAtError = -1
    end
    
    methods
        function errorMessage(this, msg, id, varargin)
            b = getBanner(this);
            b.setMessage('error', msg, id, varargin{:});
            this.CurrentObjectAtError = this.Figure.CurrentObject;
        end
        
        function warningMessage(this, msg, id, varargin)
            b = getBanner(this);
            b.addMessage('warning', msg, id, varargin{:});
        end
        
        function msg = getCurrentMessage(this)
            banner = this.Banner;
            if isempty(banner)
                msg = [];
            else
                msg = getMessage(this.Banner);
            end
        end
        
        function clearAllMessages(this)
            b = this.Banner;
            if ~isempty(b)
                removeAllMessages(b);
            end
        end
        
        function removeMessage(this, id)
            b = this.Banner;
            if ~isempty(b)
                removeMessage(b, id);
            end
        end
    end
    
    methods (Access = protected)
        function b = getBanner(this)
            
            b = this.Banner;
            if isempty(b)
                
                % Figure and Layout must be defined by the subclass.
                b = matlabshared.application.Banner(this.Figure); %#ok<*MCNPN>
                b.IsWebFigure = useAppContainer(this.Application);
                if isprop(this, 'Layout') && ~b.IsWebFigure
                    addlistener(this.Layout, 'LayoutPerformed', @this.onLayoutPerformed);
                end
                this.Banner = b;
            end
        end
        
        function onLayoutPerformed(this, ~, ~)
            % No need to call getBanner.  Banner must be populated if this
            % is being called.
            resize(this.Banner);
        end
    end
end

% [EOF]
