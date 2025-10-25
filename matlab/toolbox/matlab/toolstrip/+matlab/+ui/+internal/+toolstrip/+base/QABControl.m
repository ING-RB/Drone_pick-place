classdef (Abstract) QABControl < matlab.ui.internal.toolstrip.base.Control
    % Base class for MCOS QAB controls.
    
    % Copyright 2019 The MathWorks, Inc.
    
    % Public methods
    methods
        
        %% Constructor
        function this = QABControl(type, varargin)
            % Constructor "QABControl": 
            
            % super
            this = this@matlab.ui.internal.toolstrip.base.Control(type, varargin{:});
            
            % process custom property
            if nargin > 1 && isa(varargin{1}, 'matlab.ui.internal.toolstrip.base.Action')
                this.setAction(varargin{1});
            else
                this.processCustomProperties(varargin{:});
            end
            % default no text
            this.ShowText = false;
        end

    end

    methods (Hidden = true)
        
        function addedToQuickAccess(this, isAdded)
            if nargin < 2 || ~islogical(isAdded)
                isAdded = true;
            end
            this.Action.IsInQuickAccess = isAdded;
        end

        function render(this, channel, parent, varargin)
            % Overload method "render"
            %
            % Workaround for g2448620: Create the widget viewmodel node
            % directly under the parent.

            % Make sure the parent is a QuickAccessGroup object and has a
            % viewmodel node.
            if isa(parent, 'matlab.ui.internal.toolstrip.impl.QuickAccessGroup')...
                    && hasPeerNode(parent) && viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(parent.Peer)
                if ~hasPeerNode(this)
                    % Viewmodel node doesn't exist for QABControl

                    this.PeerModelChannel = channel;
                    widget_properties = this.getWidgetProperties();
                    this.createPeerDirectlyWithinParent(widget_properties, parent);

                    % create action peer node
                    this.Action.render([channel '_Action']);
                    % link action peer node to widget peer node
                    this.setPeerProperty('actionId', this.Action.Id);
                else
                    % Viewmodel node already exists, in that case, just do
                    % the move.
                    this.moveToTarget(parent,varargin{:});
                end
            else
                % Parent doesn't exist or parent is a peer model node, call
                % the render method of Container.
                render@matlab.ui.internal.toolstrip.base.Control(this, channel, parent, varargin{:});
            end
        end

    end

    methods (Access = protected)
        function createPeerDirectlyWithinParent(this, props_struct, parent)
            type = this.Type;

            manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(this.PeerModelChannel);
            parent_node = parent.Peer;
            this.Manager = manager;

            % create peer node and add it to parent
            this.Peer = parent_node.addChild(type, props_struct);
            % add listener to peer node event coming from client node
            this.Peer.addEventListener('propertySet', @(event, data) PropertySetCallback(this, event, data));
            this.Peer.addEventListener('peerEvent', @(event, data) PeerEventCallback(this, event, data));
        end
    end
end
