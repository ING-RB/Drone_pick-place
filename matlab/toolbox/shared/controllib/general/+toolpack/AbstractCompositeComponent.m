classdef AbstractCompositeComponent < toolpack.AbstractAtomicComponent & toolpack.Container
    % Abstract class providing default implementations for a composite
    % component.
    %
    % This class subclasses from TOOLPACK.ABSTRACTATOMICCOMPNENT and
    % TOOLPACK.CONTAINER to provide its functionalities. The Database of
    % this composite component tracks the components it holds by name and
    % their interconnection using a  component-port-connector paradigm. The
    % Database does not carry therefore any of the handle objects
    % themselves. These are stored in private properties that are not
    % stored when this composite component is stored.
    %
    % Loading a composite component means:
    % - Instantiating all children components by calling their constructors
    %   providing their workspace which is stored in the Database of the
    %   composite component.
    % - Rewiring components according the connections information stored in
    %   the Database.
    %
    % This tool component has the following independent, internal, and
    % output elements.
    %
    %    Inputs (stored ~Hold):  ADD
    %                            REMOVE
    %                            CONNECT
    %                            DISCONNECT
    %
    %    States (stored):        COMPONENTS   struct('Name',.,'Class',.,'Database',.)
    %                            CONNECTIONS  struct('Name',.,'SrcComponent',.,'SrcPort',.,'DstComponent',.,'DstPort',.)
    %
    %    Outputs (not stored):   
    %
    %  Subclasses must provide implementations for the following methods:
    %    preAddTasks               -
    %    postAddTasks              -
    %    preResetChildrenTasks     -
    %    postResetChildrenTasks    -
    %    preUpdateChildrenTasks    -
    %    postUpdateChildrenTasks   -
    %    preOutputChildrenTasks    -
    %    postOutputChildrenTasks   -
    %
    %  and the following methods inherited from TOOLPACK.ABSTRACTATOMICCOMPONENT
    %    processInportEvents       -
    %
    %  Subclasses must call:
    %
    %    this = this@toolpack.AbstractAtomicComponent(DB)
    %
    %  where DB, if provided, must be a TOOLPACK.DATABASE object.
    %
    %  The following new properties and methods are defined by this class. For
    %  inherited properties and methods, type DOC followed by the full
    %  classname.
    %
    %  AbstractCompositeComponent Properties:
    %    N/A
    %
    %  AbstractCompositeComponent Methods:
    %    add                       - adds a component; sets ADD in ChangeSet
    %    remove                    - removes a component; sets REMOVE in ChangeSet
    %    connect                   - adds a connector; sets CONNECT in ChangeSet
    %    disconnect                - removes a connector; sets DISCONNECT in ChangeSet
    %    get                       - returns the handle to a component provided its name
    %    getComponents             - returns handles to all held components
    %    getDiagram                - gets the blue print of the composition
    %    saveobj                   - define the save process for the object
    %    reload                    - define the load process for the object
    %
    %  See also AbstractAtomicComponent, AbstractGraphicalComponent.
    
    % Author(s): Bora Eryilmaz
    % Revised: Murad Abu-Khalaf
    % Copyright 2010-2011 The MathWorks, Inc.
    
    
    %% ------ MODEL CONSTRUCTION
    methods (Access = public)
        function this = AbstractCompositeComponent(varargin)
            % ABSTRACTCOMPOSITECOMPONENT The constructor of the composite
            % tool component.
            
            this = this@toolpack.AbstractAtomicComponent(varargin{:});
        end
    end
    
    %% ------ SERILIZATION
    methods
        function S = saveobj(obj) %#ok<STOUT,MANU>
            S = [];
            % Define the save process for the object
            % S.Children = obj.Children;
        end
        
        function obj = reload(obj, S) %#ok<INUSD>
            % Define the load process for the object
            %obj.Components_ = S.Children;
        end
    end
    
    %% ------ INPUTS
    methods (Access = public)
        
        function add(this, child)
            % Add child component to this composite component "container".           
            this.preAddTasks(child);
            
            try
                add@toolpack.Container(this,child);
            catch E                
                rethrow(E);
            end
            
            try
                this.ChangeSet.ADD = child.Name;
                this.update;
            catch E
                remove(this,child.Name);
                rethrow(E);
            end
            
            this.postAddTasks(child);
        end
        
        function remove(this, name)
            % Remove child component NAME from this composite component "container".            
            if ~isAncestorOf(this,getComponent(this,name))
                return;
            end
            this.ChangeSet.REMOVE = {name};
            try
                remove@toolpack.Container(this,name);
                this.update;
            catch E
                rethrow(E);
            end
        end
        
        function removeAll(this)
            % Remove child component NAME from this composite component "container".
            names  = cellfun(@(c) c.Name, this.Components_,'UniformOutput',false);
            this.ChangeSet.REMOVE = names;
            try
                removeAll@toolpack.Container(this);
                this.update;
            catch E
                rethrow(E);
            end
        end
        
        function connect(this, src, dest)
            % Connect to child components.
            SrcComponent = src(1:((strfind(src,'/')-1)));
            SrcPort = src(((strfind(src,'/')+1)):end);
            DstComponent = dest(1:((strfind(dest,'/')-1)));
            DstPort = dest(((strfind(dest,'/')+1)):end);
            this.ChangeSet.CONNECT = {[src '_' dest],SrcComponent,SrcPort,DstComponent,DstPort};
            this.update;
        end
        
        function disconnect(this, src, dest)
            srcName = src(1:((strfind(src,'/')-1)));
            srcPort = src(((strfind(src,'/')+1)):end);
            destName = dest(1:((strfind(dest,'/')-1)));
            destPort = dest(((strfind(dest,'/')+1)):end);
            this.ChangeSet.DISCONNECT = {srcName,srcPort,destName,destPort};
            this.update;            
        end
        
    end
    
    
    %% ------ STATES
    methods (Access = protected)
        
        % Implementing getIndependentVariables
        function props = getIndependentVariables(this) %#ok<MANU>
            props = {'ADD','REMOVE','CONNECT','DISCONNECT'};
        end
        
        % Implementing mStart
        function mStart(this)
            s = struct('Name',{},'Class',{},'Database',{});
            this.Database = struct(...
                'ADD', [], ...         % Input
                'REMOVE', {{}}, ...    % Input
                'CONNECT', [], ...     % Input
                'DISCONNECT', [], ...  % Input
                'COMPONENTS', s ,...   % States
                'CONNECTIONS', []);    % States
        end
        
        % Implementing mReset
        % Reset all independent variables and current state to their default
        % values.
        function mReset(this)
            preResetChildrenTasks(this);
            
            % Call reset on all children.
            c = this.getComponents;
            if ~isempty(c)
                for i=1:numel(c)
                    c{i}.reset;
                end
            end
            
            postResetChildrenTasks(this);
        end
        
        % Implementing mCheckConsistency
        function mCheckConsistency(this) %#ok<MANU>
        end
        
        % Implementing mUpdate
        function updateData = mUpdate(this)
            preUpdateChildrenTasks(this);
            
            % Initialize event data
            updateData =  [];
            
            props = this.getIndependentVariables;
            % Synchronize independent properties. This assume
            % mCheckConsistency has already been executed and that the
            % ChangeSet data can be moved to DataBase
            for k = 1:length(props)
                p = props{k};
                if isfield(this.ChangeSet, p)
                    this.Database.(p) = this.ChangeSet.(p);
                end
            end
            
            % Update internal state
            
            % ADD
            if isfield(this.ChangeSet, 'ADD')
                
                name = this.ChangeSet.ADD;
                comp = this.getComponent(name);
                s = struct(...
                    'Name',comp.Name,...
                    'Class',class(comp),...
                    'Database',comp.getDatabase);
                
                this.Database.COMPONENTS = [this.Database.COMPONENTS;s];
            end
            
            % REMOVE
            if isfield(this.ChangeSet, 'REMOVE')
                comps = this.ChangeSet.REMOVE;
                names  = {this.Database.COMPONENTS.Name};
                idx = false;
                for i=1:numel(comps)
                    idx = or(idx,strcmp(comps{i},names));
                end                
                this.Database.COMPONENTS(idx) = [];
                
%                 % Disconnect connectors to which this component is a source
%                 srcnames = {this.Database.CONNECTORS.SrcComponent};
%                 idxSrc = find(strcmp(comp.Name,srcnames),1);
%                 this.Database.CONNECTORS(idxSrc) = [];
%                 
%                 % Disconnect connectors to which this component is a
%                 % destination
%                 dstnames = {this.Database.CONNECTORS.DstComponent};
%                 idxDst = find(strcmp(comp.Name,dstnames),1);
%                 this.Database.CONNECTORS(idxDst) = [];
            end
            
            % CONNECT
            if isfield(this.ChangeSet, 'CONNECT')
                
                Name = this.ChangeSet.CONNECT{1};
                SrcComponent = this.ChangeSet.CONNECT{2};
                SrcPort = this.ChangeSet.CONNECT{3};
                DstComponent = this.ChangeSet.CONNECT{4};
                DstPort = this.ChangeSet.CONNECT{5};
                
                try
                    hSrcPort  = this.get(SrcComponent).Outport(SrcPort);
                    hDstPort = this.get(DstComponent).Inport(DstPort);
                    wire = toolpack.Connector(hSrcPort,hDstPort);
                catch E
                    rethrow(E);
                end
                
                this.Connectors_ = [this.Connectors_; wire];
                
                s = struct('Name',Name,'SrcComponent',SrcComponent,...
                    'SrcPort',SrcPort,'DstComponent',DstComponent,...
                    'DstPort',DstPort);
                this.Database.CONNECTIONS = [this.Database.CONNECTIONS;s];
            end
            
            % DISCONNECT
            if isfield(this.ChangeSet, 'DISCONNECT')
                Name = this.ChangeSet.DISCONNECT{1};
                SrcComponent = this.ChangeSet.DISCONNECT{2};
                SrcPort = this.ChangeSet.DISCONNECT{3};
                DstComponent = this.ChangeSet.DISCONNECT{4};
                DstPort = this.ChangeSet.DISCONNECT{5};
                s1 = struct('Name',Name,'SrcComponent',SrcComponent,...
                    'SrcPort',SrcPort,'DstComponent',DstComponent,...
                    'DstPort',DstPort);
                c1 = struct2cell(s1);
                c1 = c1(2:end); % Remove Name
                s2 = this.Database.CONNECTIONS;
                idx = [];
                for i=1:numel(s2)
                    c2 = struct2cell(s2(i));
                    c2 = c2(2:end); % Remove Name
                    idx = cat(1,idx, strcmp(c1,c2));
                end
                this.Connectors_(idx) = [];
                this.Database.CONNECTIONS(idx) = [];
            end
            
            % Clear Inputs processed and do not hold onto them (~Hold)
            this.Database.ADD = [];
            this.Database.REMOVE = {};
            this.Database.CONNECT = [];
            this.Database.DISCONNECT = [];            
            
            % Call update on all children.
            c = this.getComponents;
            if ~isempty(c)
                for i=1:numel(c)
                    c{i}.update;
                end
            end
            
            postUpdateChildrenTasks(this);
        end
        
        % Implementing mOutput
        % Compute stored outputs from current state and independent variables.
        function mOutput(this)
            preOutputChildrenTasks(this);
            
            % (A) Compute expensive stored outputs using lazy evaluation
            
            % (B) Compute stored outputs that are not expensive directly
            
            % Call update on all children.
            c = this.getComponents;
            if ~isempty(c)
                for i=1:numel(c)
                    c{i}.output;
                end
            end
            
            postOutputChildrenTasks(this);
        end
        
        % Implementing mGetState
        function state=mGetState(this)
            state = [this.Database.COMPONENTS;
                this.Database.CONNECTIONS];
        end
        
        % Implementing mSetState
        function mSetState(this,state)
            this.Database.COMPONENTS = state(1);
            this.Database.CONNECTIONS = state(2);
        end
        
    end
    
    
    %% ------ OUTPUTS
    methods (Access = public)
        
        % STORED OUTPUTS
        function y = getDiagram(this) %#ok<STOUT,MANU>
            % GETDIAGRAM  Show components and their interconnection.
        end
        
        % NOT STORED OUTPUTS
    end
    
    
    %% ------ USER-DEFINED METHODS    
    methods (Abstract = true, Access = protected)
        
        % Do some optional checking of the child before allowing it in.
        preAddTasks(this,child);
        
        % Perform custom tasks after adding components, like wiring.
        postAddTasks(this,child);        
        
        % Implement any tasks prior to resetting the children of this
        % container. If resetting means deleting those children, then this
        % is where that could be done.
        preResetChildrenTasks(this);
        
        % Realizing that resetting a container is not necessarily
        % equivalent to resetting the individual children, any extra tasks
        % come here.
        postResetChildrenTasks(this);
        
        preUpdateChildrenTasks(this);
        postUpdateChildrenTasks(this);
        
        preOutputChildrenTasks(this);
        postOutputChildrenTasks(this);
        
    end
    
end