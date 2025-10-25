classdef ResponseStyleManager < matlab.mixin.SetGet & matlab.mixin.Copyable
    %% Properties (notifies ResponseStyleManagerChanged event)
    properties (AbortSet)
        ColorOrder = localInitializeColorOrder()
        LineStyleOrder = {'-';'--';'-.';':'}
        MarkerOrder = {'none';'x';'o';'+';'*';'s';'d';'p'}
    end

    properties (AbortSet,Hidden)
        SemanticColorOrder (:,1) string = controllib.plot.internal.utils.GraphicsColor(1:7).SemanticName
        ColorOrderMode = "auto"
    end

    properties (Dependent, AbortSet)
        SortByColor 
        SortByLineStyle 
        SortByMarker 
    end
    
    %% Properties
    properties (Access = private)
        NextStyleIndex = 1;
        SortByColor_I = "response"
        SortByLineStyle_I = "none"
        SortByMarker_I = "none"
    end
   
    %% Events
    events
        ResponseStyleManagerChanged
    end
    
    %% Public methods
    methods
        function this = ResponseStyleManager()
        end

        function styles = getAllUniqueStyles(this) 
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
            end           
            % Get number of styles
            if strcmpi(this.SortByColor,"response")
                nStyles = length(this.ColorOrder);
            elseif strcmpi(this.SortByLineStyle,"response")
                nStyles = length(this.LineStyleOrder);
            elseif strcmpi(this.SortByMarker,"response")
                nStyles = length(this.MarkerOrder);
            else
                nStyles = 1;
            end
            % Get each unique style
            styles = createArray([nStyles 1],'controllib.chart.internal.options.ResponseStyle');
            for k = 1:nStyles
                styles(k) = getStyle(this,k);
            end
        end

        function style = getNextStyle(this)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
            end
            style = getStyle(this,this.NextStyleIndex);
            this.NextStyleIndex = this.NextStyleIndex + 1;
        end
        
        function style = getStyle(this,idx)
            % "getStyle" returns the style object for the k-th response
            %   style = getStyle(StyleManager,2)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                idx (1,1) double {mustBePositive,mustBeInteger}
            end
            % Create style objects
            style = controllib.chart.internal.options.ResponseStyle();

            % Fill in style objects
            % RE: The Colors, LineStyles, and Markers arrays define how style attributes are
            %     distributed across the axes grid. Colors is set to
            %       * 1x1 cell for uniform color
            %       * 1x1xN cell for sorting responses in response array by colors
            %       * Nx1 cell for sorting outputs by colors
            %       * 1xN cell for sorting inputs by colors
            %     (N is the number of colors). Similarly for LineStyles and Markers.
            switch this.SortByColor
                case 'none'
                    if strcmp(this.ColorOrderMode,"auto")
                        style.ColorOrder = this.ColorOrder(1);
                        style.ColorMode = "auto";
                    else
                        style.ColorOrder = this.SemanticColorOrder(1);
                        style.ColorMode = "semantic-auto";
                    end
                case 'response'
                    if strcmp(this.ColorOrderMode,"auto")
                        ct = 1 + mod(idx-1,length(this.ColorOrder));
                        style.ColorOrder = this.ColorOrder(ct);
                        style.ColorMode = "auto";
                    else
                        ct = 1 + mod(idx-1,length(this.SemanticColorOrder));
                        style.ColorOrder = this.SemanticColorOrder(ct);
                        style.ColorMode = "semantic-auto";
                    end
                case 'responseArray'
                    if strcmp(this.ColorOrderMode,"auto")
                        style.ColorOrder = reshape(this.ColorOrder,1,1,size(this.ColorOrder,1));
                    else
                        style.ColorOrder = reshape(this.SemanticColorOrder,1,1,size(this.SemanticColorOrder,1));
                    end
                case 'input'
                    if strcmp(this.ColorOrderMode,"auto")
                        style.ColorOrder = reshape(this.ColorOrder,1,length(this.ColorOrder));
                    else
                        style.ColorOrder = reshape(this.SemanticColorOrder,1,length(this.SemanticColorOrder));
                    end
                case 'output'
                    if strcmp(this.ColorOrderMode,"auto")
                        style.ColorOrder = reshape(this.ColorOrder,length(this.ColorOrder),1);
                    else
                        style.ColorOrder = reshape(this.SemanticColorOrder,length(this.SemanticColorOrder),1);
                    end
            end
            style.FaceColorOrder = style.ColorOrder;
            style.EdgeColorOrder = style.ColorOrder;

            switch this.SortByLineStyle
                case 'none'
                    style.LineStyleOrder = this.LineStyleOrder(1);
                case 'response'
                    ct = 1 + mod(idx-1,length(this.LineStyleOrder));
                    style.LineStyleOrder = this.LineStyleOrder(ct);
                case 'responseArray'
                    style.LineStyleOrder = reshape(this.LineStyleOrder,1,1,length(this.LineStyleOrder));
                case 'input'
                    style.LineStyleOrder = reshape(this.LineStyleOrder,1,length(this.LineStyleOrder));
                case 'output'
                    style.LineStyleOrder = reshape(this.LineStyleOrder,length(this.LineStyleOrder),1);
            end
            style.LineStyleMode = "auto";

            switch this.SortByMarker
                case 'none'
                    style.MarkerStyleOrder = this.MarkerOrder(1);
                case 'response'
                    ct = 1 + mod(idx-1,length(this.MarkerOrder));
                    style.MarkerStyleOrder = this.MarkerOrder(ct);
                case 'responseArray'
                    style.MarkerStyleOrder = reshape(this.MarkerOrder,1,1,length(this.MarkerOrder));
                case 'input'
                    style.MarkerStyleOrder = reshape(this.MarkerOrder,1,length(this.MarkerOrder));
                case 'output'
                    style.MarkerStyleOrder = reshape(this.MarkerOrder,length(this.MarkerOrder),1);
            end 
            style.MarkerStyleMode = "auto";
        end
    
        function resetColorOrder(this)
            this.ColorOrder = localInitializeColorOrder();
        end
    end
    
    %% Get/Set
    methods
        % Color Order
        function set.ColorOrder(this,ColorOrder)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                ColorOrder (:,1) cell
            end
            % Do not set ColorOrder if the SemanticColorOrder has been set
            % at any point. This will ensure that a new ColorOrder does not
            % override the already set SemanticColorOrder when the theme
            % changes
            oldValue = this.ColorOrder;
            try
                this.ColorOrder = ColorOrder;
                notify(this,'ResponseStyleManagerChanged');
            catch ex
                this.ColorOrder = oldValue;
                throw(ex);
            end
        end

        % Semantic Color Order
        function set.SemanticColorOrder(this,SemanticColorOrder)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                SemanticColorOrder (:,1) string
            end
            oldValue = this.SemanticColorOrder;
            oldModeValue = this.ColorOrderMode;
            try
                this.SemanticColorOrder = SemanticColorOrder;
                this.ColorOrderMode = "semantic";
                notify(this,'ResponseStyleManagerChanged');
            catch ex
                this.SemanticColorOrder = oldValue;
                this.ColorOrderMode = oldModeValue;
            end
        end

        % ColorMode
        function set.ColorOrderMode(this,ColorOrderMode)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                ColorOrderMode (1,1) string
            end
            this.ColorOrderMode = ColorOrderMode;
            notify(this,"ResponseStyleManagerChanged");
        end
        
        % LineStyle Order
        function set.LineStyleOrder(this,LineStyleOrder)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                LineStyleOrder (1,:) cell
            end
            oldValue = this.LineStyleOrder;
            try
                this.LineStyleOrder = LineStyleOrder;
                notify(this,'ResponseStyleManagerChanged');
            catch ex
                this.LineStyleOrder = oldValue;
                throw(ex);
            end
        end
        
        % Marker Order
        function set.MarkerOrder(this,MarkerOrder)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                MarkerOrder (1,:) cell
            end
            oldValue = this.MarkerOrder;
            try
                this.MarkerOrder = MarkerOrder;
                notify(this,'ResponseStyleManagerChanged');
            catch ex
                this.MarkerOrder = oldValue;
                throw(ex);
            end
        end
        
        % Sort By Color
        function SortByColor = get.SortByColor(this)
            SortByColor = this.SortByColor_I;
        end
        
        function set.SortByColor(this,SortByColor)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                SortByColor (1,1) string {mustBeMember(SortByColor,["none","response","input","output","responseArray"])}
            end
            this.SortByColor_I = SortByColor;
            % If conflict, set SortByLineStyle/SortByMarker to none
            if strcmp(this.SortByColor_I,this.SortByLineStyle_I)
                this.SortByLineStyle_I = "none";
            end
            if strcmp(this.SortByColor_I,this.SortByMarker_I)
                this.SortByMarker_I = "none";
            end
            notify(this,'ResponseStyleManagerChanged');
        end
        
        % Sort By Marker
        function SortByMarker = get.SortByMarker(this)
            SortByMarker = this.SortByMarker_I;
        end
        function set.SortByMarker(this,SortByMarker)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                SortByMarker (1,1) string {mustBeMember(SortByMarker,["none","response","input","output","responseArray"])}
            end
            this.SortByMarker_I = SortByMarker;
            % If conflict, set SortByLineStyle/SortByColor to none
            if strcmp(this.SortByMarker_I,this.SortByLineStyle_I)
                this.SortByLineStyle_I = "none";
            end
            if strcmp(this.SortByMarker_I,this.SortByColor_I)
                this.SortByColor_I = "none";
            end
            notify(this,'ResponseStyleManagerChanged');
        end
        
        % Sort By Line Style
        function SortByLineStyle = get.SortByLineStyle(this)
            SortByLineStyle = this.SortByLineStyle_I;
        end
        
        function set.SortByLineStyle(this,SortByLineStyle)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyleManager
                SortByLineStyle (1,1) string {mustBeMember(SortByLineStyle,["none","response","input","output","responseArray"])}
            end
            this.SortByLineStyle_I = SortByLineStyle;
            % If conflict, set SortByColor/SortByMarker to none
            if strcmp(this.SortByLineStyle_I,this.SortByColor_I)
                this.SortByColor_I = "none";
            end
            if strcmp(this.SortByLineStyle_I,this.SortByMarker_I)
                this.SortByMarker_I = "none";
            end
            notify(this,'ResponseStyleManagerChanged');
        end
    end
end

%% Local functions
function colorOrder = localInitializeColorOrder()
colorOrder = get(groot,'DefaultAxesColorOrder');
colorOrder = mat2cell(colorOrder,ones(1,size(colorOrder,1)),3);
end