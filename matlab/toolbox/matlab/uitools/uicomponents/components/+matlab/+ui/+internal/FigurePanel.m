classdef FigurePanel < matlab.ui.container.internal.appcontainer.Panel
    %FigurePanel Represents an AppContainer Panel comprised of a Figure
    %   The base class provides the ability to set and get Figure Panel properties
    %   as well as listen for changes to the same.

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        Figure;    % DivFigure handle
        FigureInitialized = false;
    end
    
    methods
        function this = FigurePanel(varargin)
            % create the base class Panel
            this = this@matlab.ui.container.internal.appcontainer.Panel(varargin{:});
            
            factory.Modules(1) = matlab.ui.internal.FigureModuleInfo;
			
            % set the Factory used for Figure-based panels
            this.Factory = factory;

            % All AppContainer FigurePanels are currently docked, though by default they have no isDocked property.
            % DivFigures are created with "normal" WindowStyle, and WindowStyle is boarded up for web Figures,
            % so we have to remove web graphics restrictions while we set WindowStyle
            % on the Figure itself, to synchronize the Model so things work properly.
            % TODO: remove all but the property set line once WindowStyle is unboarded.
            WGR = feature('WebGraphicsRestriction');
            c = onCleanup(@()feature('WebGraphicsRestriction', WGR));
            feature('WebGraphicsRestriction', 0);
            this.Figure.WindowStyle = 'docked';
            this.Figure.DockControls = 'off';
            feature('WebGraphicsRestriction', WGR);
            
            % Now that the Model is updated, get the packet and add it as Content to pass to the factory
            % so it can establish communications between the client and server Figure elements.
            dfPacket = matlab.ui.internal.FigureServices.getDivFigurePacket(this.Figure);
            this.Content = dfPacket;
        end % FigurePanel constructor
        
        function delete(obj)
            delete(obj.Figure);
        end % FigurePanel destructor

        function value = get.Figure(this)
            if ~this.FigureInitialized
                this.Figure = matlab.ui.internal.divfigure();
                this.FigureInitialized = true;
            end
            value = this.Figure;
        end
        
    end % methods

    methods (Access = protected)

        % g2595603 - need to apply property sets on the panel 
        % to the model as well, because there is a lag between when this
        % FigurePanel object is created, and when the client side
        % bootstraps.  If we do not do this for all "shared truth"
        % properties between this object and the Figure model, the values
        % in this object will be overwritten by values from the Figure
        % model when its client side bootstraps.
        function setProperty(this, name, value)
            setProperty@matlab.ui.container.internal.appcontainer.Panel(this, name, value);
            
            if ~isvalid(this) || ~isvalid(this.Figure) || isempty(this.Figure)
                return;
            else
                switch ( name )
                    case 'Title'
                        this.Figure.Name = value;
                end
            end
        end
    end

end