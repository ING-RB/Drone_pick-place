classdef BaseWorkspaceAdapter < toolpack.AbstractAtomicComponent & internal.matlab.datatoolsservices.WorkspaceListener
    % Provide apps with two-way access to Base Workspace.
    %
    % BaseWorkspaceAdapter Methods:
    %    clear                   - clears a variable in the stack
    %    assignin                - assigns a variable in the stack
    %    evalin                  - evaluate expression in the stack
    %    who                     - List current variables
    %    whos                    - list current variables, long form
    %    duplicate               - Duplicates given variables in the stack
    %    rename                  - renames a variable
    %
    % It is used by a few control apps that access base workspace in the
    % Simulink workflow such as "slctrlguis.lintool.getVariablesOfType"
    %
    % Typical use case is to make it a property of the app data class.
    % Initialize it in constructor and must manually delete it in the class
    % destructor to aoiv memory leak.
    
    %   Author(s): Murad Abu-Khalaf , July 30, 2010
    %   Revised: R. Chen, Mar 2024 (for Java removal work)
    %   Copyright 2010-2024 The MathWorks, Inc.
    
    
    %% ----------------------------------- %
    % Properties                           %
    % ------------------------------------ %
    properties (Access = private)
        % Workspace action data set by "workspaceUpdated" and used by "mUpdate"
        BaseWSEventData_
        % Rename action data set by "rename" and used by "mUpdate" method
        RenameData_
    end
    
    
    %% ----------------------------------- %
    % Model and View Construction          %
    % ------------------------------------ %
    methods (Access = public)
        
        % Constructor
        function this = BaseWorkspaceAdapter(varargin)
            % Call parent class constructor
            this = this@toolpack.AbstractAtomicComponent(varargin{:});
            this = this@internal.matlab.datatoolsservices.WorkspaceListener();
            % Initialize if not initialized and generates output (null)
            output(this);
        end
        
    end
    
    methods
        
        % Workspace action callback implemented for the "WorkspaceListener" mixed-in 
        function workspaceUpdated(this, varNames, wksEvents)
            % process base workspace event information, use it to update
            % BaseWSEventData_, and then call "update" to deliver it. 
            if ~isempty(varNames) && ~isempty(wksEvents)
                eventdata = struct('WSChange',false,...
                                    'WSDelete',false,...
                                    'WSClear',false);
                switch wksEvents
                    case {'VARIABLE_CHANGED', 'VARIABLE_ADDED'}
                        eventdata.WSChange = true;
                    case 'VARIABLE_DELETED'
                        eventdata.WSDelete = true;
                    case 'WORKSPACE_CLEARED'
                        eventdata.WSClear = true;
                end
                if eventdata.WSChange || eventdata.WSDelete || eventdata.WSClear
                    this.BaseWSEventData_ = eventdata;
                else
                    this.BaseWSEventData_ = [];
                end
                update(this);
            end
        
        end

    end

    methods (Static)
        
        function obj = loadobj(S)
            % Call constructor
            obj = toolpack.databrowser.BaseWorkspaceAdapter;
            obj = reload(obj, S);
        end
        
    end
    
    
    %% ----------------------------------- %
    % Ports Construction and Handling      %
    % ------------------------------------ %
    methods (Access = protected)
        % Implementing processInportEvents
        function processInportEvents(this, src, evnt) %#ok<*INUSD>
            % dummy
        end
    end
    
    %% ----------------------------------- %
    % STATES                               %
    % ------------------------------------ %
    methods (Access = protected)
        
        % Implementing getIndependentVariables
        function props = getIndependentVariables(this) %#ok<MANU>
            % dummy
            props = {};
        end
        
        % Implementing mStart
        function mStart(this)
            % dummy
            this.Database = struct;
        end
        
        % Implementing mReset
        function mReset(this)
            % dummy
            this.Database = struct;
        end
        
        % Implementing mCheckConsistency
        function mCheckConsistency(this) %#ok<MANU>
            % dummy
        end
        
        % Implementing mUpdate
        function updateData = mUpdate(this)
            % return an event data object "WorkspaceEventData"
            updateData =  toolpack.databrowser.WorkspaceEventData;
            % add base workspace action information
            if ~isempty(this.BaseWSEventData_)
                updateData.WSChange = this.BaseWSEventData_.WSChange;
                updateData.WSDelete = this.BaseWSEventData_.WSDelete;
                updateData.WSClear = this.BaseWSEventData_.WSClear;
                % Clear ws event data
                this.BaseWSEventData_ = [];
            end
            % add "rename" action information 
            if updateData.WSChange && ~isempty(this.RenameData_)
                oldname = this.RenameData_{1};
                newname = this.RenameData_{2};
                updateData.WSRename = true;
                updateData.setRenameData(oldname,newname);
                % Clear the rename data
                this.RenameData_ = [];
            end
            %disp(updateData) % for debug use
        end
        
        % Implementing mOutput
        function mOutput(this) %#ok<MANU>
            % dummy
        end
        
        % Implementing mGetState
        function state=mGetState(this) %#ok<MANU>
            % dummy
            state = [];
        end
        
        % Implementing mSetState
        function mSetState(this,state) 
            % dummy
        end
        
    end

    %% ----------------------------------- %
    % Wrappers and/or Common methods       %
    % ------------------------------------ %
    methods (Access = public)
        
        function clear(this, varargin) 
            % CLEAR  Clears the variable specified.
            %
            %   CLEAR(OBJ, VAR1, VAR2, ...) clears the specified variables
            %   from base workspace.
            %
            %   VAR1, VAR2, ... are strings representing the variables to
            %   be cleared from the workspace. If the variable does not
            %   exists, nothing happens.
            %
            %   See also ASSIGNIN.
            
            if isempty(varargin)
                evalin('base','builtin(''clear'')');
            else
                for i=1:numel(varargin)
                    evalin('base',['builtin(''clear'',' '''' varargin{i} '''' ')' ]);
                end
            end
        end
        
        function assignin(this, varargin) 
            % ASSIGNIN  Assigns a variable in the workspace.
            %
            %   ASSIGNIN(OBJ,VARNAME, VARVALUE) assigns the value VARVALUE
            %   to the variable VARNAME in the base workspace.
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
            for i=1:2:ni
                if isvarname(varargin{i})
                    varName = varargin{i};
                else
                    ctrlMsgUtils.error('Controllib:databrowser:InvalidVariableNames');
                end
                varValue = varargin{i+1};
                builtin('assignin','base',varName,varValue);
                %assignin('base',varName,varValue); NEVER USE because when
                %varValue is a LocalWorkspaceModel, then its assignin
                %method is called instead.
            end
        end
        
        function varargout = evalin(this, expression) 
            % EVALIN  Evaluate expression in the workspace.
            %
            %   EVALIN(OBJ,'expression') evaluates 'expression' in the
            %   context of base workspace.
            %
            %   [X,Y,Z,...] = EVALIN(OBJ,'expression') returns output
            %   arguments from the expression.
            %
            %   See also ASSIGNIN.
            n = nargout;
            if n == 0
                evalin('base',expression);
            else                
                str = getOutStr(n);                    
                eval([str ' = ' 'evalin(''base'',' '''' expression '''' ');' ]);
                varargout = cell(n,1);
                for i=1:n
                    varargout{i} = eval(['y' num2str(i)]);
                end
            end
        end
        
        function varargout = who(this, varargin) 
            % WHO  List current variables.
            %
            %   C = WHO(OBJ) returns a cell array containing the names
            %   of the variables in the LocalWorkspaceModel with object
            %   OBJ.
            %
            %   See also WHOS.
            
            if isempty(varargin)
                exp = 'builtin(''who'')';
            else
                if numel(varargin) == 2 && ischar(varargin{1}) && ischar(varargin{2}) && ...
                        strcmpi(varargin{1},'-regexp')
                    pattern = varargin{2};
                    exp = ['builtin(''who'',''-regexp'',''' pattern ''')'];
                else
                    ctrlMsgUtils.error('Controllib:databrowser:RegexpOnly');
                end            
            end
            
            if nargout == 0
                exp = strrep(exp,'''','''''');
                str = evalc(['evalin(''base'',''' exp ''')']);
                disp(deblank(str));
            else
                vars = evalin('base',exp);
                n = numel(vars);
                if n==0
                    varargout = {{}};
                else
                    varargout = {vars};
                end
            end            
        end
        
        function S = whos(this,varargin) 
            % WHOS  List current variables, long form.
            %
            %   S = WHOS(OBJ) returns a structure with fields:
            %       name        -- variable name
            %       size        -- variable size
            %       bytes       -- number of bytes allocated for the array
            %       class       -- class of variable
            %
            %   See also WHO.
            
            if isempty(varargin)
                exp = 'builtin(''whos'')';
            else
                if numel(varargin) == 2 && ischar(varargin{1}) && ischar(varargin{2}) && ...
                        strcmpi(varargin{1},'-regexp')
                    pattern = varargin{2};
                    exp = ['builtin(''whos'',''-regexp'',''' pattern ''')'];
                else
                    ctrlMsgUtils.error('Controllib:databrowser:RegexpOnly');
                end            
            end            
            S = evalin('base',exp);
            S = rmfield(S,{'global','nesting','persistent'});
        end
        
        function duplicate(this, varargin)
            % DUPLICATE  Duplicates given variables in the workspace.
            %
            %   DUPLICATE(OBJ, 'VAR1', 'VAR2',...) creates new variables
            %   in the base workspace that have the same value of the
            %   provided variables names VAR1,VAR2,... but with different
            %   names.
            %
            %   See also RENAME.
            
            % All variable names must be strings
            chk = cellfun(@isvarname,varargin, 'UniformOutput', true);
            if ~all(chk)
                ctrlMsgUtils.error('Controllib:databrowser:InvalidVariableNames');
            end
            for i=1:numel(varargin)
                cNames = this.who;
                copyname = workspacefunc('getcopyname',varargin{i},cNames);
                builtin('assignin','base',copyname,evalin('base',varargin{i}));
                % Must use builtin, otherwise, if the value of the
                % assignment is a handle object that also has the method
                % assignin, that method might be called and not the builtin
                % one.
            end
        end
        
        function rename(this, oldname, newname)
            % RENAME  Modifies the name of an existing workspace
            % variable.
            %
            %   RENAME(OBJ, OLDNAME, NEWNAME) renames the workspace
            %   variable OLDNAME to NEWNAME.
            %
            %   OLDNAME must be a string representing the name of an
            %   existing variable in the base workspace.
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
            this.RenameData_ = {oldname,newname};
            evalin('base',[newname '=' oldname ';']);
            evalin('base',['builtin(''clear'', ''' oldname ''' )']);
        end
    end
    
end

%% ----------------------------------- %
% Local functions                      %
% ------------------------------------ %
function str = getOutStr(n)
    str = '';
    if n~=0
        for i=1:n
            str = [str 'y' num2str(i) ' ']; %#ok<AGROW>
        end
        str = ['[ ' str ']'];
    end
end
