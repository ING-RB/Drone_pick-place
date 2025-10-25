classdef AbstractAtomicComponent < handle
    %Abstract class providing default implementations for the model of a
    %tool component.
    %
    %  Subclasses must provide implementations for the methods:
    %    getIndependentVariables   -
    %    mStart                    -
    %    mReset                    -
    %    mCheckConsistency         -
    %    mUpdate                   -
    %    mOutput                   -
    %    mGetState                 -
    %    mSetState                 -
    %    processInportEvents       -
    %    createView                -
    %
    %  Subclasses should call:
    %
    %    this = this@toolpack.AbstractAtomicComponent(DB)
    %
    %  where DB, if provided, must be a TOOLPACK.DATABASE object.
    %
    %  The following new properties and methods are defined by this class. For
    %  inherited properties and methods, type DOC followed by the full
    %  classname.
    %
    %  AbstractAtomicComponent Properties:
    %    Name                      - Name of the component
    %    Inport                    - Receive communication from other tool components
    %    Outport                   - Send communication to other tool components
    %
    %  AbstractAtomicComponent Methods:
    %    addInport                 - enables an Inport to this tool component
    %    addOutport                - enables an Outport to this tool component
    %    writeToOutport            - writes DATA to Outport IDX
    %    reset                     - resets the initialized model to its default state
    %    setup                     - configures the component for the first time
    %    output                    - updates the component outputs
    %    update                    - updates the component state and compute outputs
    %    getState                  - get current state
    %    setState                  - set current state
    %    setParent                 - sets the parent container if any.
    %    getParent                 - returns the parent container if any.
    %    getDatabase               - return database
    %    setDatabase               - replace database overwriting existing data
    %    switchDatabase            - assign a new database an return existing data
    %    saveobj                   - defines the save process for the object
    %    reload                    - defines the load process for the object
    %
    %  See also AbstractGraphicalComponent, AbstractCompositeComponent.
    
    % Author(s): Bora Eryilmaz
    % Revised: Murad Abu-Khalaf
    % Copyright 2010-2011 The MathWorks, Inc.
    
    
    %% ----------------------------------- %
    % Properties                           %
    % ------------------------------------ %
    properties (Dependent, Access = protected)
        % Component data (structure, default = struct with no field).
        Database
        % Uncommitted data changes (structure, default = struct with no field).
        ChangeSet
    end
    
    properties (Access = private)
        % Database object handle (acts as private data for Database property).
        Database_
        
        % Structure or [] for default value struct.
        ChangeSet_
        
        % Parent container
        Parent_
    end
    
    properties (Access = protected)
        % Logical. Set to true upon component initialization.
        Initialized = false;
        % Version
        Version = toolpack.ver();
    end
    
    properties (Access = public)
        % Name of the component (No spaces allowed)
        Name
    end
    
    properties (Access = public, Hidden = true)
        % Receive communication from other tool components
        Inport
        
        % Send communication to other tool components
        Outport
    end
    
    %% ----------------------------------- %
    % Events                               %
    % ------------------------------------ %
    events (Hidden = false, ListenAccess = 'public', NotifyAccess = 'public')
        % Event sent upon component change.  Event data is passed using a
        % ComponentEventData object.
        ComponentChanged
    end
    
    %% ----------------------------------- %
    % Atomic Component Construction        %
    % ------------------------------------ %
    methods
        function this = AbstractAtomicComponent(varargin)
            % Constructor.
            %
            % Subclasses should call
            %   obj = obj@toolpack.AbstractAtomicComponent( varargin{:} )
            if nargin < 1
                % Default argument
                dbs = toolpack.Database;
            else
                dbs = varargin{1};
            end
            this.setDatabase(dbs);
        end
        
        function delete(this)
            %disp([class(this) ' is deleting...']);
            
            p = this.getParent;
            if isa(p,'toolpack.Container') && isvalid(p)
                p.remove(this.Name);
            end
        end
    end
    
    %% ----------------------------------- %
    % SERILIZATION                         %
    % ------------------------------------ %
    methods
        function S = saveobj(obj)
            % Define the save process for the object
            S.Version = obj.Version;
            S.Database_ = obj.Database_;
            % Unapplied data in obj.ChangeSet_ are not saved.
            S.Initialized = obj.Initialized;
        end
        
        function obj = reload(obj, S)
            % Define the load process for the object
            obj.Version = S.Version;
            obj.Database_ = S.Database_;
            % Data in obj.ChangeSet_ is not modified from struct S.
            obj.Initialized = S.Initialized;
        end
    end
    
    %% ----------------------------------- %
    % Ports Construction and Handling      %
    % ------------------------------------ %
    methods (Access = protected)
        function addInport(this, number)
            % ADDINPORT(OBJ,IDX) enables an Inport to this tool
            % component and return its handle. IDX is a string index
            % representing an integer.
            if ~isempty(this.Inport)
                portnumbers = {this.Outport.PortNumber};
                if any(strcmp(portnumbers,number))
                    return;
                end
            end
            p = toolpack.Port(this,number);
            addlistener(p, 'PortChanged', @this.processInportEvents);
            this.Inport = [this.Inport p];            
        end
        function addOutport(this, number)
            % ADDOUTPORT(OBJ,IDX) enables an Outport to this tool
            % component and return its handle. IDX is a string index
            % representing an integer.
            if ~isempty(this.Outport)
                portnumbers = {this.Outport.PortNumber};
                if any(strcmp(portnumbers,number))
                    return;
                end
            end
            this.Outport = [this.Outport toolpack.Port(this,number)];
        end
    end
    methods (Access = public)
        function writeToOutport(this, portnumber, data)
            % WRITETOOUTPORT(OBJ,IDX,DATA) writes DATA to Outport IDX.
            portnumbers = {this.Outport.PortNumber};
            idx = find(strcmp(portnumber,portnumbers), 1);
            if ~isempty(idx)
                this.Outport(idx).Data = data;
            else
                ctrlMsgUtils.error('Controllib:databrowser:InvalidPort',portnumber);
            end
        end
    end
    
    
    %% ----------------------------------- %
    % User-defined methods                 %
    % ------------------------------------ %
    methods (Abstract = true, Access = protected)
        
        % Return list of independent variable names.
        props = getIndependentVariables(this);
        
        % Perform initial setup and one-time-only calculations.  Assign model
        % parameters.
        mStart(this);
        
        % Reset all independent variables and current state to their default
        % values.
        mReset(this);
        
        % Check component data consistency.  Error out if changes are inconsistent
        % with the current state of the component.
        mCheckConsistency(this);
        
        % Compute next state from current state and independent variables.
        updateData = mUpdate(this);
        
        % Compute stored outputs from current state and independent variables.
        mOutput(this);
        
        % Return the state of the component (structure or [] for default value
        % struct).
        state = mGetState(this);
        
        % Set the current state by passing a struct argument.
        mSetState(this, state);
        
        % How to handle Inport events
        processInportEvents(this, src, evnt);
        
    end
    
    %     methods (Abstract = true, Access = public)
    %         % Create the "View" for this model
    %         view = createView(this, varargin);
    %     end
    
    
    %% ----------------------------------- %
    % Component Execution                  %
    % ------------------------------------ %
    methods (Sealed)
        function reset(this)
            % Resets the component to its default state if it has been already
            % initialized.
            if this.Initialized;
                this.ChangeSet = [];
                mReset(this)
            else
                % No effect on uninitialized components.
                ctrlMsgUtils.warning('Controllib:toolpack:UninitializedComponent')
            end
        end
        
        function setup(this)
            % Configures the component for the first time.
            if ~this.Initialized
                mStart(this);
                this.ChangeSet = [];
                mReset(this);
                this.Initialized = true; % This could be set in CompositeComponent in its mReset
            else
                % No effect on initialized components.
                ctrlMsgUtils.warning('Controllib:toolpack:InitializedComponent')
            end
        end
        
        function this = output(this)
            % Updates the component outputs.
            
            % Initialize the component if it has not been initialized before.
            if ~this.Initialized
                setup(this);
            end
            
            % Use state and input (if direct feedthrough) values to calculate (or
            % clear) stored output values.
            mOutput(this);
        end
        
        function this = update(this)
            % Updates the component state and compute outputs.            
            try
                % Initialize the component if it has not been initialized before.
                if ~this.Initialized
                    setup(this);
                end
                
                % Check joint property consistency.
                mCheckConsistency(this)
                
                % Update component state.
                updateData = mUpdate(this);
                
                % Use state and input (if direct feedthrough) values to calculate (or
                % clear) stored output values.
                mOutput(this);
                
                % Component is now up-to-date.
                this.ChangeSet = [];
                
                % Notify listeners with event information
                if isempty(updateData)
                    notify(this, 'ComponentChanged', toolpack.ComponentEventData(''))
                else
                    notify(this, 'ComponentChanged', updateData)
                end
            catch E
                this.ChangeSet = []; % To avoid accumulating inputs that errors
                throwAsCaller(E)
            end            
        end
        
        function state = getState(this)
            % Get the current state.
            if this.Initialized
                state = mGetState(this);
                if isempty(state)
                    state = struct; % default
                end
            else
                % No effect on uninitialized components.
                ctrlMsgUtils.warning('Controllib:toolpack:UninitializedComponent')
                state = struct;
            end
        end
        
        function setState(this, state)
            % Set the current state.
            if this.Initialized
                mSetState(this, state);
            else
                % No effect on uninitialized components.
                ctrlMsgUtils.warning('Controllib:toolpack:UninitializedComponent')
            end
        end
        
        function setParent(this,container)
            % Set the parent container
            this.Parent_ = container;
        end
        
        function r = getParent(this)
            % Return the parent container
            r = this.Parent_;
        end
    end
    
    %% ----------------------------------- %
    % Component Database Management        %
    % ------------------------------------ %
    methods (Sealed)
        function wksp = getDatabase(this)
            % Return Database.
            wksp = this.Database_;
        end
        
        function setDatabase(this, wksp)
            % Replace Database overwriting existing data.
            this.Database_ = wksp;
        end
        
        function wksp_old = switchDatabase(this, wksp_new)
            % Assign a new Database while keeping existing data.
            wksp_old = this.getDatabase;
            data = this.Database; % current data
            this.setDatabase(wksp_new);
            % Restore existing data in new Database.
            this.Database = data;
        end
    end
    
    methods
        function value = get.ChangeSet(this)
            % GET function for ChangeSet property.
            value = this.ChangeSet_;
            if isempty(value)
                value = struct; % default
            end
        end
        
        function set.ChangeSet(this, value)
            % SET function for ChangeSet property.
            if isempty(value)
                value = [];
            else
                if isstruct(value)
                    props = this.getIndependentVariables;
                    fields = fieldnames(value);
                    idxs = ismember(fields, props);
                    if ~all( idxs )
                        fname = fields(idxs==0);
                        ctrlMsgUtils.error('Controllib:toolpack:NotAnIndependentProperty', fname{1})
                    end
                else
                    ctrlMsgUtils.error('Controllib:toolpack:InvalidPropertyValue', 'ChangeSet')
                end
            end
            this.ChangeSet_ = value;
        end
        
        function value = get.Database(this)
            % GET function for Database property.
            
            % Protect against deleted Database. This allows public
            % workspace API to be robust when it is being accessed while
            % the workspace itself is being destroyed.
            if ~isvalid(this.Database_)
                ctrlMsgUtils.error('Controllib:toolpack:UninitializedComponent')
            end
            
            value = this.Database_.Data;
            if isempty(value)
                value = struct; % default
            end
        end
        
        function set.Database(this, value)
            % SET function for Database property.
            
            if isempty(value)
                value = [];
            elseif ~isstruct(value)
                ctrlMsgUtils.error('Controllib:toolpack:InvalidPropertyValue', 'Database')
            end
            this.Database_.Data = value;
        end
        
        function set.Database_(this, wksp)
            % Set function for Database_ property.
            if ~(isempty(wksp) || isa(wksp, 'toolpack.Database'))
                ctrlMsgUtils.error('Controllib:toolpack:InvalidDatabaseArgument')
            end
            this.Database_ = wksp;
        end
        
        function set.Name(this,aName)
            % Set the name of the component
            if isempty(this.getParent)
                this.Name = aName;
            else
                ctrlMsgUtils.error('Controllib:databrowser:CannotRename');
            end
        end
        
    end
    
    
end
