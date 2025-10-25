classdef LocalWorkspaceModel < toolpack.AbstractAtomicComponent
    % This class creates a tool component providing workspace
    % functionalities. This means maintaining and managing a stack of
    % workspace variables with a protected namespace.
    %
    % This tool component has the following stored inputs, states, and
    % outputs.
    %
    %    Inputs (stored):        IN
    %                            OUT
    %
    %    States (stored):        STACK
    %
    %    Outputs (stored):       WhosInformation
    %
    % The following new properties and methods are defined by this class:
    %
    % LocalWorkspaceModel Methods:
    %    setIN                   - sets IN in ChangeSet
    %    setOUT                  - sets OUT in ChangeSet
    %    getIN                   - gets IN from DataBase
    %    getOUT                  - gets OUT from DataBase
    %    getWhosInformation      - gets WhosInformation from DataBase
    %    getWho                  - returns Who
    %    getValue                - returns the value of a variable
    %    isVar                   - checks if variable is in the stack
    %    clear                   - clears a variable in the stack
    %    assignin                - assigns a variable in the stack
    %    evalin                  - evaluate expression in the stack
    %    who                     - List current variables
    %    whos                    - list current variables, long form
    %    duplicate               - Duplicates given variables in the stack
    %    rename                  - renames a variable
    %
    %   See also toolpack.AbstractAtomicComponent, toolpack.databrowser.WorkspaceView
    
    %   Author(s): Murad Abu-Khalaf , July 30, 2010
    %   Revised:
    %   Copyright 2010-2020 The MathWorks, Inc.
    
    %% ------ PROPERTIES
     properties (Access = private)
        %  Data to be read by the mUpdate method
        RenameData_
        %  ID - unique id for isequal
        ID
    end
    
    %% ------ MODEL CONSTRUCTION
    methods (Access = public)
        
        % Constructor
        function this = LocalWorkspaceModel(varargin)
            % LOCALWORKSPACEMODEL  The constructor of the tool component
            % that provides workspace functionalities.
            
            % Call parent class constructor
            this = this@toolpack.AbstractAtomicComponent(varargin{:});
            
            % Add Inports/Outports            
            
            % Will setup system if not initialized and generates output
            output(this);
            
            % Setup a unique ID
            this.ID = now;
        end
        
    end
    
    methods (Access = public)
        
        % Equality test - true only if the handles refer to the same instance
        function out = isequal(obj, in)
            out = builtin('isequal',obj,in) && isequal(obj.ID, in.ID);
        end
        
    end
    
    %% ------ SERILIZATION
    methods
        
        % Overriding saveobj
        function S = saveobj(obj)
            S = saveobj@toolpack.AbstractAtomicComponent(obj);
            
            % Anything extra to save comes here
            % S.foo = obj.bar
        end
        
        % Overriding reload
        function obj = reload(obj, S)
            obj = reload@toolpack.AbstractAtomicComponent(obj, S);
            
            % Anything extra to reload comes here
            % obj.bar = S.foo
        end
        
    end
    methods (Static)
        
        function obj = loadobj(S)
            % Call constructor
            obj = toolpack.databrowser.LocalWorkspaceModel;
            obj = reload(obj, S);
        end
        
    end
    
    %% ------ PORTS CONSTRUCTION AND HANDLING
    methods (Access = protected)
        % Implementing processInportEvents
        function processInportEvents(this, src, evnt) %#ok<INUSD,MANU>
        end
    end
    
    
    %% ------ INPUTS
    methods (Access = public, Hidden = true)
        
        function setIN(this, varargin)
            % SETIN  Modifies the independent input variable IN.
            %
            %   SETIN(OBJ,ARG) sets the field IN in the ChangeSet
            %   property of the LocalWorkspaceModel object OBJ.
            %
            %   ARG must be an existing variable in the caller
            %   workspace or an anonymous variable resulting from valid
            %   MATLAB expression that evaluates in the caller's workspace.
            %   The following are some examples:
            %
            %     OBJ.setIN(tf(1,[1 2]));
            %     OBJ.setIN(sysC);
            %
            %   SETIN(OBJ,varname1,value1,varname2,value2,...) is an
            %   alternative way to set variable(s). For example,
            %
            %     obj.setIN('varA',tf(1,[1 1]);
            %
            %   creates a variable called varA that is a transfer function.
            %
            %   The default value for IN is {}, or cell(0). To clear the IN
            %   field and reset it to its default value, type
            %
            %     OBJ.setIN;
            %
            %   See also GETIN.
            
            ni = nargin - 1;
            
            % Handle OBJ.setIN
            if ni==0
                this.ChangeSet.IN = {};
            elseif ni==1 % Handle the 1 variable case
                name = inputname(2);
                if isempty(name)
                    name = 'ans'; % Default name
                end
                this.ChangeSet.IN = {name,varargin{1}};
            else % Handle the multi variable case
                if mod(ni,2)~=0
                    ctrlMsgUtils.error('Controllib:databrowser:InconsistentNameValuePair');
                end
                varnames  = varargin(1:2:end);
                chk = cellfun(@isvarname,varnames, 'UniformOutput', true);
                if ~all(chk)
                    ctrlMsgUtils.error('Controllib:databrowser:InvalidVariableNames');
                end
                this.ChangeSet.IN = varargin;
            end
        end
        
        function setOUT(this, varargin)
            % SETOUT  Modifies the independent input variable OUT.
            %
            %   SETOUT(OBJ,VARNAME1, VARNAME2,...) sets the field OUT in
            %   the ChangeSet property of the LocalWorkspaceModel object
            %   OBJ.
            %
            %   VARNAMES must be a cell array of strings each representing
            %   the name of a variable in the workspace of the tool
            %   component object.
            %
            %   The default value for OUT is {}, or cell(0). To set the
            %   default value, you only need to type
            %
            %     OBJ.setOUT;
            %
            %   See also GETOUT.
            
            ni = nargin;
            
            % Handle OBJ.setOUT
            if ni==1
                this.ChangeSet.OUT = {};
                return;
            end
            chk = cellfun(@isvarname,varargin, 'UniformOutput', true);
            if ~all(chk)
                ctrlMsgUtils.error('Controllib:databrowser:InvalidVariableNames');
            end
            this.ChangeSet.OUT = varargin;
        end
        
        function r = getIN(this)
            % GETIN  Access the value of the independent input variable IN.
            %
            %   C = GETIN(OBJ) returns the cell array held by the field IN
            %   in the Database property of the LocalWorkspaceModel
            %   object OBJ. Default values is {[],[],''}.
            %
            %   See also SETIN.
            
            r = this.Database.IN;
        end
        
        function r = getOUT(this)
            % GETOUT  Access the value of the independent input variable
            % OUT.
            %
            %   STR = GETOUT(OBJ) returns the string held by the field OUT
            %   in the Database property of the LocalWorkspaceModel
            %   object OBJ. Default values is ''.
            %
            %   See also SETOUT.
            
            r = this.Database.OUT;
        end
        
    end
    
    
    %% ------ STATES
    methods (Access = protected)
        
        % Implementing getIndependentVariables
        function props = getIndependentVariables(this) %#ok<MANU>
            props = {'IN','OUT'};
        end
        
        % Implementing mStart
        function mStart(this)
            this.Database = struct(...
                'IN', {}, ...
                'OUT', {}, ...
                'STACK', struct, ...
                'WhosInformation', struct ...
                );
        end
        
        % Implementing mReset
        function mReset(this)
            this.Database.IN = {};
            this.Database.OUT = {};
            this.Database.STACK = struct;
            this.Database.WhosInformation = struct;
        end
        
        % Implementing mCheckConsistency
        function mCheckConsistency(this)
            if isempty(this.ChangeSet)
                return;
            end
            
            % Get independent variables from Database
            props = this.getIndependentVariables;
            s = struct(this.Database);
            strs = fieldnames(s);
            for k = 1:length(props)
                % Delete other variables from Database
                strs = strs(~strcmp(props{k},strs));
            end
            s = rmfield(s, strs);
            
            % Synchronize and overlap independent variables with requested
            % changes.
            if isfield(this.ChangeSet, 'IN')
                s.IN = this.ChangeSet.IN;
            else
                % Do not validate with what is saved in Database.IN or
                % Database.OUT from previous updates with what is being
                % requested now via ChangeSet.IN or ChangeSet.OUT.
                s.IN = {};
            end
            if isfield(this.ChangeSet, 'OUT')
                s.OUT = this.ChangeSet.OUT;
            else
                % Do not validate with what is saved in Database.IN or
                % Database.OUT from previous updates with what is being
                % requested now via ChangeSet.IN or ChangeSet.OUT.
                s.OUT = {};
            end
            
            % Cross validate requested changes to the independent variables
            % The only rule here is that a variable of the same name should
            % not appear in IN and OUT at the same time.
            INnames = s.IN(1:2:end);
            OUTnames = s.OUT;
            if numel(OUTnames)==0
                return;
            else
                for i=1:numel(OUTnames)
                    chk = cellfun(@(x) strcmp(OUTnames{i},x),INnames, 'UniformOutput', true);
                    if any(chk)
                        % Clean up ChangeSet. Done in superclass. Otherwise
                        % calling update will error again.
                        ctrlMsgUtils.error('Controllib:databrowser:CannotAddRemove');
                    end
                end
            end
        end
        
        % Implementing mUpdate
        function updateData = mUpdate(this)
            % Initialize event data
            updateData =  toolpack.databrowser.WorkspaceEventData;
            
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
            % NOTE: The inputs are only considered in ChangeSet. Prior
            % inputs held at Database.IN and Database.OUT from previous
            % iterations are not conisdered. That is, this is not an apply
            % and hold paradigm.
            if isfield(this.ChangeSet, 'IN') % This is to avoid doing unnecessary work
                varnames  = this.Database.IN(1:2:end);
                varvalues = this.Database.IN(2:2:end);
                for i=1:numel(varnames)
                    name  = varnames{i};
                    value = varvalues{i};
                    this.Database.STACK.(name) = value;
                    updateData.WSChange = true;
                end
                %updateData.WSChange = true % This will cause a WSChange to
                %be true when modifying the IN field to empty
            end
            
            % Clear the requested variables if they exist. No errors
            % otherwise
            if isfield(this.ChangeSet,'OUT') % This is to avoid doing unnecessary work
                p  = this.Database.OUT;
                for i=1:numel(p)
                    if isfield(this.Database.STACK, p{i})
                        this.Database.STACK = rmfield(this.Database.STACK, p{i});
                        updateData.WSDelete = true;
                    end
                end
                if updateData.WSDelete && isempty(fieldnames(this.Database.STACK))
                    updateData.WSDelete = false;
                    updateData.WSClear = true; % This supports obj.evalin('clear')
                end
            end
            
            if isfield(this.ChangeSet, 'IN') || isfield(this.ChangeSet, 'OUT') 
                % This is to avoid doing unnecessary work Order fields.
                % This must be done in order to use the PresortedTableModel
                % capability in Java's RecordlistTableModel
                if isstruct(this.Database.STACK)
                    this.Database.STACK = orderfields(this.Database.STACK);
                end
            end
            
            % Handle RENAME event data
            if ~isempty(this.RenameData_)
                oldname = this.RenameData_{1};
                newname = this.RenameData_{2};
                updateData.WSRename = true;
                updateData.setRenameData(oldname,newname);
                % Clear the rename data
                this.RenameData_ = [];
            end
        end
        
        % Implementing mOutput
        function mOutput(this)
            
            % (A) Compute expensive stored outputs using lazy evaluation
            this.Database.WhosInformation = struct;
            
            % (B) Compute stored outputs that are not expensive directly
        end
        
        % Implementing mGetState
        function state=mGetState(this)
            state = this.Database.STACK;
        end
        
        % Implementing mSetState
        function mSetState(this,state)
            this.Database.STACK = state;
        end
        
    end
    
    
    %% ------ OUTPUTS
    methods (Access = public, Hidden = true)
        
        % STORED OUTPUTS
        function y = getWhosInformation(this)
            % GETWHOSINFORMATION  List current variables, long form.
            %
            %   S = GETWHOSINFORMATION(OBJ) returns a structure held by the
            %   field WHOSINFORMATION in the Database property of the
            %   LocalWorkspaceModel with object OBJ. The fields of
            %   the returned structure S are as follows:
            %       name        -- variable name
            %       size        -- variable size
            %       bytes       -- number of bytes allocated for the array
            %       class       -- class of variable
            %
            %   This output is created only once for each update.
            %
            %   See also GETVALUE.
            
            if isempty(fieldnames(this.Database.WhosInformation))
                % Recompute if cleared and store for subsequent reads.
                
                toolpack.databrowser.LocalWorkspaceModel.this(this);
                clear this;
                % Cache the database stack into this method's stack
                toolpack.databrowser.LocalWorkspaceModel.cacheSTACK;
                y = whos;
                CAll = fieldnames(y);
                CKeep = {'name';'size';'bytes';'class';'sparse';'complex'};
                idx = false(numel(CAll),1);
                for i=1:numel(CKeep)
                    idx = or(idx,strcmp(CKeep{i},CAll));
                end
                CAll(idx) = [];
                y = rmfield(y,CAll);
                this = toolpack.databrowser.LocalWorkspaceModel.this;
                this.Database.WhosInformation = y;
                % Clean up to make sure no memory leak
                toolpack.databrowser.LocalWorkspaceModel.this('cleanup');
                return;
            end
            y = this.Database.WhosInformation;
        end
        
        % NOT STORED OUTPUTS
        function C = getWho(this)
            % GETWHO  List current variables.
            %
            %   C = GETWHO(OBJ) returns a cell array containing the names
            %   of the variables in the LocalWorkspaceModel with object
            %   OBJ.
            %
            %   See also GETWHOSINFORMATION.
            
            s = struct(this.Database.STACK);
            C = fieldnames(s);
        end
        
        function y = getValue(this, varname)
            % GETVALUE  Access the value of the variable VARNAME.
            %
            %   P = GETVALUE(OBJ,VARNAME) returns the value of the
            %   variable VARNAME stored in the LocalWorkspaceModel
            %   object OBJ.
            %
            %   VARNAME must be a string representing the name of an
            %   existing variable in the workspace of the tool component
            %   object.
            %
            %   See also GETWHOSINFORMATION.
            
            s = struct(this.Database.STACK);
            if isfield(s, varname)
                y = s.(varname);
            else
                ctrlMsgUtils.error('Controllib:databrowser:InvalidWorkspaceVariable',varname);
            end
        end
        
        function F = isVar(this,varname)
            % ISVAR  Returns if a variable exists in current workspace.
            %
            %   F = ISVAR(OBJ,VARNAME) returns a logical value that
            %   indicates whether the variable VARNAME exists in the
            %   LocalWorkspaceModel with object OBJ.
            %
            %   VARNAME must be a string representing the name of the
            %   workspace variable.
            
            s = struct(this.Database.STACK);
            C = fieldnames(s);
            F = any(strcmp(varname,C));
        end
        
    end
    
    
    %% ------ WRAPPERS AND/OR COMMON METHODS
    methods (Access = public)
        
        function clear(this, varargin)
            % CLEAR  Clears the variable specified.
            %
            %   CLEAR(OBJ, VAR1, VAR2, ...) clears the specified variables
            %   stored in the LocalWorkspaceModel object OBJ.
            %
            %   VAR1, VAR2, ... are strings representing the variables to
            %   be cleared from the workspace of the tool component object.
            %   If the variable does not exists, nothing happens.
            %
            %   See also ASSIGNIN.
            
            % Protect against database destruction. Some variables may want
            % to clear themselves from the workspace when they are deleted
            % after the database itself is destroyed.
            try
                this.Database;
            catch E %#ok<NASGU>
                % Errors when Database is destroyed
                return;
            end
            
            if isempty(varargin)
                vars = this.who;
            else
                vars = varargin;
            end            
            
            try
                this.setOUT(vars{:});
                this.setIN;
                % Ensures new variables are not added accidentally and/or
                % the same variable name is not in the IN field.
            catch E
                throw(E);
            end
            this.update;
        end
        
        function assignin(this, varargin)
            % ASSIGNIN  Assigns a variable in the workspace.
            %
            %   ASSIGNIN(OBJ,VARNAME, VARVALUE) assigns the value VARVALUE
            %   to the variable VARNAME and stors it in the
            %   LocalWorkspaceModel object OBJ.
            %
            %   VARNAME is a string representing the variable name.
            %   VARVALUE is the value associated with the variable.
            %
            %   ASSIGNIN(OBJ,VAR1NAME,VAR1VALUE,VAR2NAME,VAR2VALUE,...)
            %   supports a multi variable assignment in a single workspace
            %   update.
            %
            %   See also EVALIN.
            
            ni = nargin - 1;
            
            if mod(ni,2)~=0
                ctrlMsgUtils.error('Controllib:databrowser:InconsistentNameValuePair');
            end
            res = [];
            for i=1:2:ni
                if isvarname(varargin{i})
                    varName = varargin{i};
                else
                    ctrlMsgUtils.error('Controllib:databrowser:InvalidVariableNames');
                end
                varValue = varargin{i+1};
                res = cat(2,res,{varName,varValue});
            end
            try
                this.setIN(res{:});
                this.setOUT;
                % Not this ensures that nothing is accidentally deleted.
                % May happen if this.Database.OUT = 'var1' and 'var1' is in
                % the database and was not removed in the latest updated
                % due to some errors later in mUpdate after info was moved
                % from ChangeSet to Database. If we do not do this step and
                % this field was not empty, most likely nothing will be
                % deleted because generally mUpdate should have already
                % deleted that, and multiple request to delete a deleted
                % variable do not error out.
            catch E
                throw(E);
            end
            this.update;
        end
        
        function varargout = evalin(varargin)
            % EVALIN  Evaluate expression in the workspace.
            %
            %   EVALIN(OBJ,'expression') evaluates 'expression' in the
            %   context of LocalWorkspaceModel object OBJ.
            %
            %   [X,Y,Z,...] = EVALIN(OBJ,'expression') returns output
            %   arguments from the expression.
            %
            %   See also ASSIGNIN.
            
            % Checks to see if this expression is an existing variable name
            % to be evaluated. This does not cause a workspace update.
            varname = varargin{2};
            if ~isempty(varname) && (strcmp(varname(end),',') || strcmp(varname(end),';'))
                % Robust to ',' and ';' to support evalin expressions
                varname(end) = [];
            end
            if varargin{1}.isVar(varname)
                varargout = {varargin{1}.getValue(varname)};
                return;
            end
            clear varname;
            
            % Assign STACK variables to the workspace of this method and avoid
            % name clash with VARARGIN:
            %
            % 1- Save the object handle to protect it against a "clear"
            % operation requested via obj.evalin('clear');. Note we
            % currently have NO protection against obj.evalin('clear all');
            %
            % 2- Populate the workspace of this function (this stack) with
            % variables stored at STACK.
            
            % Store the handle and the expression in a safe place
            toolpack.databrowser.LocalWorkspaceModel.this(varargin{1});
            toolpack.databrowser.LocalWorkspaceModel.expression(varargin{2});
            
            % Cache the database stack into this method's workspace
            toolpack.databrowser.LocalWorkspaceModel.cacheSTACK;
            
            % The code below does not pollute this method's workspace
            if (nargout == 0)
                eval(toolpack.databrowser.LocalWorkspaceModel.expression);
                toolpack.databrowser.LocalWorkspaceModel.updateSTACK;
                clear varargout;
            else
                % NOTE: assigning the output arguments at this point to
                % varargout is safe. Changes to the workspace of this
                % method has been captured, and hence if varargout
                % overrides a variable that happens to be also called
                % varargou, then no problem. We are SAFE! This will pass
                % the following test:
                %
                %  Example,
                %    ws = toolpack.databrowser.LocalWorkspaceModel;
                %    ws.evalin('varargout = 1.234');
                %    s = evalin(ws,'logical(exist(''aStruct'',''var''))');
                %
                varargout = toolpack.databrowser.LocalWorkspaceModel.safeOutEval(nargout);
                
                % NOTE: Cannot use
                %
                %    varargout{1:nargout} = ...
                %
                % It does not support nargout >= 2
            end
            
            % Clear persistent variables to guarantee no memory leak
            toolpack.databrowser.LocalWorkspaceModel.this('cleanup');
            toolpack.databrowser.LocalWorkspaceModel.expression(0);
        end
        
        function varargout = who(this, varargin)
            % WHO  List current variables.
            %
            %   C = WHO(OBJ) returns a cell array containing the names
            %   of the variables in the LocalWorkspaceModel with object
            %   OBJ.
            %
            %   See also WHOS.
            
            vars = this.getWho;
            if ~isempty(varargin)
                if numel(varargin) == 2 && ischar(varargin{1}) && ischar(varargin{2}) && ...
                        strcmpi(varargin{1},'-regexp')
                    pattern = varargin{2};
                    match = regexp(vars, pattern);
                    idx = cellfun(@isempty,match);
                    vars(idx) = [];
                else
                    ctrlMsgUtils.error('Controllib:databrowser:RegexpOnly');
                end
            end
            
            n = numel(vars);
            if nargout == 0
                if n==0
                    disp('');
                else
                    str = 'Your variables are:\n\n';
                    for i=1:n
                        % Column size is formatted differently in the
                        % built-in WHO
                        str = [str vars{i} '  ']; %#ok<AGROW>
                    end
                    C = sprintf(str);
                    disp(C);
                end
            else
                if n==0
                    varargout = {{}};  % REVISE: IS this line really needed? -MURAD
                else
                    varargout = {vars};
                end
            end
        end
        
        function S = whos(this,varargin)
            % WHOS  List current variables, long form.
            %
            %   S = WHOS(OBJ) returns a structure held by the
            %   field WHOSINFORMATION in the Database property of the
            %   LocalWorkspaceModel with object OBJ. The fields of
            %   the returned structure S are as follows:
            %       name        -- variable name
            %       size        -- variable size
            %       bytes       -- number of bytes allocated for the array
            %       class       -- class of variable
            %
            %   See also WHO.
            
            S = this.getWhosInformation;
            
            vars = this.getWho;
            if ~isempty(varargin)
                if numel(varargin) == 2 && ischar(varargin{1}) && ischar(varargin{2}) && ...
                        strcmpi(varargin{1},'-regexp')
                    pattern = varargin{2};
                    match = regexp(vars, pattern);
                    idx = cellfun(@isempty,match);
                    S(idx) = [];
                else
                    ctrlMsgUtils.error('Controllib:databrowser:RegexpOnly');
                end
            end
            
        end
        
        function duplicate(this, varargin)
            % DUPLICATE  Duplicates given variables in the workspace.
            %
            %   DUPLICATE(OBJ, 'VAR1', 'VAR2',...) creates new variables
            %   that have the same value of the provided variables names
            %   VAR1,VAR2,... but with different names and stores it in
            %   OBJ.
            %
            %   See also RENAME.
            
            % All variable names must be strings
            chk = cellfun(@isvarname,varargin, 'UniformOutput', true);
            if ~all(chk)
                ctrlMsgUtils.error('Controllib:databrowser:InvalidVariableNames');
            end
            
            newVars = [];
            try
                for i=1:numel(varargin)
                    cNames = this.getWho;
                    copyname= workspacefunc('getcopyname',varargin{i},cNames);
                    newVars = cat(2,newVars,{copyname,this.getValue(varargin{i})});
                end
                this.setIN(newVars{:});
                this.setOUT;
            catch E
                throw(E);
            end
            this.update;
        end
        
        function rename(this, oldname, newname)
            % RENAME  Modifies the name of an existing workspace
            % variable.
            %
            %   RENAME(OBJ, OLDNAME, NEWNAME) renames the workspace
            %   variable OLDNAME to NEWNAME.
            %
            %   OLDNAME must be a string representing the name of an
            %   existing variable in the workspace of the tool component
            %   object.
            %
            %   NEWNAME is a string that will be used as the new name of
            %   the variable.
            %
            %   See also DUPLICATE.
            
            if ~isvarname(newname)
                ctrlMsgUtils.error('Controllib:databrowser:RenameFailed',oldname,newname);
            end
            
            if strcmp(oldname,newname)
                return;
            end
            
            varvalue = this.getValue(oldname);
            
            try
                this.RenameData_ = {oldname,newname};
                this.setIN(newname,varvalue);
                this.setOUT(oldname);
            catch E
                throw(E);
            end
            this.update;
        end
        
    end
    
    
    %% ------  HELPER PRIVATE METHODS
    methods (Static, Access = private )
        % These methods are static and are introduced as methods rather
        % than local functions to minimize the chance that they interfer
        % with variables that has the same name. For example, to avoid that
        % cacheSTACK = 2, could be actually some variable.
        
        function cacheSTACK
            % Populate the workspace in the calling method with variables
            % held my this MCOS object.
            %
            % Prior to populating, this method assumes and/or ensures that
            % the caller's workspace is clean with absolutely no variables,
            % and thus eliminating name conflict scenarios with names such
            % as varargin, varargout, this, obj, etc...
            
            % Get list of variables stored by this MCOS workspace
            vars = toolpack.databrowser.LocalWorkspaceModel.this.who;
            
            % Avoid name conflicts
            evalin('caller','clear varargin;');
            
            % Populate
            for i=1:numel(vars)
                varname = vars{i};
                value = toolpack.databrowser.LocalWorkspaceModel.this.getValue(varname);
                assignin('caller',varname,value);
            end
        end
        
        function updateSTACK
            % For this to work, the caller is assumed to be
            % evalin(obj,...). It must be invoked from that stack only!
            vars = evalin('caller','who');
            arg = [];
            for i=1:numel(vars)
                arg = cat(2,arg,',','''',vars{i},'''',',',vars{i});
            end
            
            % Update STACK in a single workspace update.
            evalin('caller',['setIN(toolpack.databrowser.LocalWorkspaceModel.this' arg ');']);
            
            % Remove variables in the DataBase not present in vars
            varsDataBase = toolpack.databrowser.LocalWorkspaceModel.this.who;
            for i=1:numel(vars)
                idx = strcmp(vars{i},varsDataBase);
                varsDataBase(idx) = [];
            end
            toolpack.databrowser.LocalWorkspaceModel.this.setOUT(varsDataBase{:});
            toolpack.databrowser.LocalWorkspaceModel.this.update;
        end
        
        function out = safeOutEval(n)
            % This method is introduced so that output arguments do not
            % conflict with legitimate workspace variables. It avoids
            % potential conflicts with names like varargout or any other
            % names to collect the output argument list.
            
            % This is needed to escape expressions with quotes:
            %
            %   Example,
            %      ws = toolpack.databrowser.LocalWorkspaceModel;
            %      s = ws.evalin('exist(''a'')');
            %
            % A new EVAL layer adds its own quotes to an expression STR, i.e.
            % 'STR', and escapes existing quotes found in STR:
            %
            %    >> eval('ispc')
            %    >> eval(eval('''ispc'''))
            %    >> eval(eval(eval('''''''ispc''''''')))
            %
            origexp = toolpack.databrowser.LocalWorkspaceModel.expression;
            newexp = strrep(origexp,char(39),[char(39) char(39)]);
            
            % Consturct output argument string. This looks like 
            % '[y1 y2 ... yn]'
            argoutstr = toolpack.databrowser.LocalWorkspaceModel.getOutStr(n);
            
            % Evaluate the expression
            eval([...
                argoutstr '=', 'evalin(''caller'',''' newexp ''');' ...
                ]);
            
            % NOTE: y1 and y2, etc... are only available in the workspace
            % of safeOutEval and not evalin. This is a big advantage as we
            % can now pass them without any name conflicts.
            
            % Call updateSTACK in case variables were added, removed or
            % re-assigned in the stack of the method evalin(obj,...).
            evalin('caller','toolpack.databrowser.LocalWorkspaceModel.updateSTACK');
            
            % Evaluate the output arguments
            out = cell(n,1);
            for i=1:n
                out{i} = eval(['y' num2str(i)]);
            end
        end
        
        function str = getOutStr(n)
            str = '';
            if n~=0
                for i=1:n
                    str = [str 'y' num2str(i) ' ']; %#ok<AGROW>
                end
                str = ['[ ' str ']'];
            end
        end
        
        function obj = this(arg)
            persistent this;
            if nargin == 1
                if strcmp(class(arg),'toolpack.databrowser.LocalWorkspaceModel')
                    this = arg;
                    return;
                else
                    clear this;
                    return;
                end
            end
            obj = this;
        end
        
        function str = expression(arg)
            persistent expression;
            if nargin == 1
                if ischar(arg)
                    expression = arg;
                    return;
                else
                    clear expression;
                    return;
                end
            end
            str = expression;
        end
        
    end
    
    
end

% ---------------------------------------------------------------------
% Avoid Local functions to minimize chances for interference with proper
% variable names
