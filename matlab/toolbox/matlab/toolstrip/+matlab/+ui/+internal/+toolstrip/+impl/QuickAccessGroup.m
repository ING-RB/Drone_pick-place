classdef QuickAccessGroup < matlab.ui.internal.toolstrip.base.Container
    % Quick Access Bar (per toolstrip)
    
    % Copyright 2013-2019 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Constructor
        function this = QuickAccessGroup()
            % super
            this = this@matlab.ui.internal.toolstrip.base.Container('QuickAccessGroup');
        end
        
        %% Add/Remove
        function add(this, item, varargin)
            if isa(item, 'matlab.ui.internal.toolstrip.base.QABControl')
                if nargin < 3
                    add@matlab.ui.internal.toolstrip.base.Container(this, item);
                else
                    % TODO: Make 'rtl' vs 'ltr' a property instead of an input string (Used in AppContainer.m)
                    if (ischar(varargin{1}) || isstring(varargin{1})) && strcmp(varargin{1}, 'rtl')                        
                        % For now we place the newest item on the left, but
                        % once the QAB can be placed below the Toolstrip, we
                        % will need to handle the direction differently
                        add@matlab.ui.internal.toolstrip.base.Container(this, item, 1);
                    else
                        add@matlab.ui.internal.toolstrip.base.Container(this, item, varargin{:});
                    end
                end
            else
                error(message('MATLAB:toolstrip:container:invalidObjectAddedToParent', str, class(this)));
            end
        end
        
        function remove(this, item)
            if isa(item, 'matlab.ui.internal.toolstrip.base.QABControl')
                if this.isChild(item)
                    remove@matlab.ui.internal.toolstrip.base.Container(this, item);
                else
                    error(message('MATLAB:toolstrip:container:invalidChild'));
                end
            else
                error(message('MATLAB:toolstrip:container:invalidObjectRemovedFromParent', class(item), class(this)));
            end
        end
        
    end
    
    %% You must initialize all the abstract methods here
    methods (Access = protected)
        
        function rules = getInputArgumentRules(this)
            % Abstract method defined in @component
            %
            % specify the rules for constructor syntax without using PV
            % pairs.  For constructor using PV pairs such as column, you
            % still need to create a dummy function though.
            rules.input0 = true;
        end

        function buildWidgetPropertyMaps(this)
            % Abstract method defined in @component
            %
            % build maps between private MCOS property names and peer node
            % property names for widget properties.  The map for action
            % properties are automatically built when creating Action
            % object.
            [mcos, peer] = this.getWidgetPropertyNames_Container();
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end

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

    methods(Hidden)
        function render(this, channel, parent, varargin)
            % Overload method "render"
            %
            % Workaround for g2448620: Create the widget viewmodel node
            % directly under the parent.

            % Make sure the parent is a QuickAccessBar object and has a
            % viewmodel node.
            if isa(parent, 'matlab.ui.internal.toolstrip.impl.QuickAccessBar')...
                    && hasPeerNode(parent) && viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(parent.Peer)
                if ~hasPeerNode(this)
                    % Viewmodel node doesn't exist for QuickAccessGroup

                    this.PeerModelChannel = channel;
                    widget_properties = this.getWidgetProperties();
                    this.createPeerDirectlyWithinParent(widget_properties, parent);
                else
                    % Viewmodel node already exists, in that case, just do
                    % the move.
                    this.moveToTarget(parent,varargin{:});
                end

                % create and move children peer nodes whenever necessary
                if ~isempty(this.Children)
                    for ct = 1:length(this.Children)
                        component = this.Children(ct);
                        component.render(channel, this);
                    end
                end
            else
                % Parent doesn't exist or parent is a peer model node, call
                % the render method of Container.
                render@matlab.ui.internal.toolstrip.base.Container(this, channel, parent, varargin{:});
            end
        end
    end

end
