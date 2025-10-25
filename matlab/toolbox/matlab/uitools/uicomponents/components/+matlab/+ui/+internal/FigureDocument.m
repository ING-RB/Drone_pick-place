classdef FigureDocument < matlab.ui.container.internal.appcontainer.Document
    %FigureDocument Represents an AppContainer Document comprised of a Figure
    %   The base class provides the ability to set and get Figure Document properties
    %   as well as listen for changes to the same.

    % Copyright 2018-2020 The MathWorks, Inc.

    properties (SetAccess = private)
        Figure;    % DivFigure handle
        FigureInitialized = false;
    end
    
    methods
        function this = FigureDocument(varargin)
            % create the base class Document
            this = this@matlab.ui.container.internal.appcontainer.Document(varargin{:});
            
            % all AppContainer FigureDocuments are currently docked.
            this.Docked = true;
  
            % DivFigures are created "normal", and WindowStyle is boarded up for web Figures,
            % so we have to remove web graphics restrictions while we set WindowStyle
            % on the Figure itself, to synchronize the Model so things work properly.
            % TODO: remove all but the property set line once WindowStyle is unboarded.
            WGR = feature('WebGraphicsRestriction');
            c = onCleanup(@()feature('WebGraphicsRestriction', WGR));
            feature('WebGraphicsRestriction', 0);
            this.Figure.WindowStyle = 'docked';
            feature('WebGraphicsRestriction', WGR);
                        
            % Now that the Model is updated, get the packet and add it as Content to pass to the factory
            % so it can establish communications between the client and server Figure elements.
            dfPacket = matlab.ui.internal.FigureServices.getDivFigurePacket(this.Figure);
            this.Content = dfPacket;
        end % FigureDocument constructor
        
        function delete(obj)
            delete(obj.Figure);
        end % FigureDocument destructor  

        function value = get.Figure(this)
            if ~this.FigureInitialized
                this.Figure = matlab.ui.internal.divfigure();
                this.FigureInitialized = true;
            end
            value = this.Figure;
        end
        
    end % methods


    methods (Access = protected)
        function handlePeerNode(this)
            handlePeerNode@matlab.ui.container.internal.appcontainer.Document(this);

            % Figure Documents are set up to always have a canCloseFcn --
            % if none exists on the document, then we will run
            % CloseRequestFcn on the Figure object.
            this.connectCloseApproverToPeerNode();
        end

        % g2595603 - need to apply property sets on the document
        % to the model as well, because there is a lag between when this
        % FigurePanel object is created, and when the client side
        % bootstraps.  If we do not do this for all "shared truth"
        % properties between this object and the Figure model, the values
        % in this object will be overwritten by values from the Figure
        % model when its client side bootstraps.
        function setProperty(this, name, value)
            setProperty@matlab.ui.container.internal.appcontainer.Document(this, name, value);
            
            if ~isvalid(this) || ~isvalid(this.Figure) || isempty(this.Figure)
                return;
            else
                switch ( name )
                    case 'Title'
                       this.Figure.Name = value;

                    case 'Visible'
                       this.Figure.Visible = value;

                    case 'EnableDockControls'
                        % Remove the restriction as EnableDockControls
                        % and DockControls should have their values in
                        % sync, and figures in AppContainers can have
                        % DockControls off while docked
                        WGR = feature('WebGraphicsRestriction');
                        c = onCleanup(@()feature('WebGraphicsRestriction', WGR));
                        feature('WebGraphicsRestriction', 0);

                        this.Figure.DockControls = value;
                end
            end
        end
    end

    methods (Access={?matlab.ui.container.internal.AppContainer, ?matlab.ui.internal.FigureDocument})
        function result = canClose(this) 
            
            % Only run the Figure's CloseRequestFcn if the Figure Document
            % does not have a CanCloseFcn defined.
            if isempty(this.CanCloseFcn) && isvalid(this.Figure)

                if isempty(this.Figure.CloseRequestFcn)
                    % In AppContainer workflows, if a user does not define
                    % either a CanCloseFcn, or a CloseRequestFcn, then we 
                    % return true, and allow the document to close.
                    result = true;
                else
                    % Otherwise, run the Figure's CloseRequestFcn (note
                    % that as per spec, this is not guaranteed to have a 
                    % return value.)
                    this.Figure.hgclose();

                    % The CanCloseFcn expects a result returned -- true for
                    % close, false for remaining open.  The Figure's
                    % CloseRequestFcn is speced so that the figure should be
                    % deleted if it is to be closed, so check validity of the
                    % this.Figure object and the containing figure document
                    if (isvalid(this) && isvalid(this.Figure))
                        result = false;
                    else
                        result = true;
                    end
                end

            else
                result = canClose@matlab.ui.container.internal.appcontainer.Document(this);
            end
        end         
    end
end