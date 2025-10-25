%

%   Copyright 2014-2023 The MathWorks, Inc.

classdef WebCanvasContainerController < matlab.ui.internal.componentframework.WebContainerController...
                                        & matlab.ui.internal.controller.CanvasController
    properties (Access = 'protected')
        PeerEventListener
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function this = WebCanvasContainerController( model, varargin )

           this = this@matlab.ui.internal.componentframework.WebContainerController( model, varargin{:} );

        end
    end
    
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       add
        %
        %  Description:  Method which runs the superclass add method and addlisterner
        %                to the 'peerEvent' for drawing the canvas.
        %
        %  Input :       webComponent -> Web component for which a peer node
        %                will be created using the Component Framework.
        %
        %  Output:       parentController -> Parent's controller.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function add( this, webComponent, parentController )
            
            try
                add@matlab.ui.internal.componentframework.WebContainerController( this, webComponent, parentController );

                % Initialize the SceneChannel value in the PeerNode
                updateSceneChannel(this);
                
            catch ME
                if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle') ...
                        && ~isvalid(this)
                    % Ignoring this one exception - Under some
                    % conditions (e.g. if a component is deleted during
                    % a drawnow callback before it is fully created)
                    % the component (and its controller) can be already
                    % deleted before this code is reached.
                    %
                    % Therefore, swallow this exception and silently
                    % return.
                else
                    rethrow(ME);
                end
            end
        end
    end
    
    methods (Access = 'protected')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Description:  handle the ClientReady event from the client
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )
            
            % Now, defer to the base class for common event processing
            handleEvent@matlab.ui.internal.componentframework.WebComponentController( obj, src, event );        
        end

        function attachView(obj)
            attachView@matlab.ui.internal.componentframework.WebComponentController(obj);

            % Attach event listener immediately after ViewModel has been created,
            % otherwise, if client side runs faster, FigureController may miss
            % event from client side as timing issue since FigureController 
            % createView() method would launch browser and start client side.
            % Moving event attaching earlier should be able to reduce
            % possibilities of sporadic test failures for those who use 
            % assertFigurePositionIsStable() by figure URL in JSD.
            obj.EventHandlingService.attachEventListener( @obj.handleEvent );
        end
    end
    
    
    methods(Access=private)
        function id = getRootId(obj)
            if ~isempty(obj.ProxyView.PeerNode.getRoot())
                id = char(obj.ProxyView.PeerNode.getRoot().getId());
            else
                id = obj.getPeerId;
            end
        end
    end
end
