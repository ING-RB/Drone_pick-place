classdef VariableEditorWorkspace < handle
%

%   Copyright 2014-2020 The MathWorks, Inc.
    
    properties
        WorkspaceID
    end
    
    properties(Access = private)
        Data_
        expression
    end
    
    methods
        function obj = VariableEditorWorkspace
            obj.WorkspaceID = now;
        end
        
        %         function varargout = evalin(this, expr)
        %             ctrluis.VariableEditorWorkspace.assigner(this.Data_);
        %             ctrluis.VariableEditorWorkspace.currentThis(this);
        %             clear this
        %             varargout{1:nargout} = ctrluis.VariableEditorWorkspace.currentThis().Data_.(expr);
        %             this = ctrluis.VariableEditorWorkspace.currentThis();
        %             ctrluis.VariableEditorWorkspace.currentThis(this);
        %         end
        %
        
        function varargout = evalin(this, expression)
            % EVALIN  Evaluate expression in the workspace.
            %
            %   EVALIN(OBJ,'expression') evaluates 'expression' in the
            %   context of theis object.
            %
            this.expression = expression;
            clear expression
            
            % assign variables from data into this function's workspace

            ctrluis.VariableEditorWorkspace.currentThis(this);
            clear this
            ctrluis.VariableEditorWorkspace.assigner(ctrluis.VariableEditorWorkspace.currentThis.Data_);
            
            try
                if (builtin('nargout') == 0)
                    eval(ctrluis.VariableEditorWorkspace.currentThis().expression);
                else
                    varargout{1:nargout} = eval(ctrluis.VariableEditorWorkspace.currentThis().expression);
                end
                
            catch e
                rethrow(e)
            end
            
            whoList = who;
            shortWhoList = cell(length(whoList) -2, 1);
%             ctrluis.VariableEditorWorkspace.currentThis(this);
            MyInternalData_ = ctrluis.VariableEditorWorkspace.currentThis.Data_; %#ok<*PROP>
            % store new variables back to data
            j = 1;
            for i = 1:length(whoList)
                switch whoList{i}
                    case {'ans','varargout'}
                        % don't store these
                        continue
                end
                shortWhoList{j} = whoList{i};
                j = j + 1;
               MyInternalData_.(whoList{i}) = eval(whoList{i});
            end
            ctrluis.VariableEditorWorkspace.currentThis;
%             clear variables that on longer exist
            fieldlist = fieldnames(MyInternalData_);
            if ~isequal(fieldlist, shortWhoList)
                for i = 1:length(fieldlist)
                    if ~any(cellfun(@(a) isequal(a,fieldlist{i}), whoList))
                        MyInternalData_ = rmfield(MyInternalData_, fieldlist{i});
                    end
                end
            end
           this = ctrluis.VariableEditorWorkspace.currentThis(); 
           this.Data_ = MyInternalData_;
        end
        
        function assignin(this, expr, val)
            this.Data_.(matlab.lang.makeValidName(expr)) = val;
            notify(this,'ComponentChanged');
        end
        
        function b = isVar(this, Var)
            b = isfield(this.Data_,Var);
        end
        
        function clear(this)
            this.Data_ = [];
        end
        
        
    end
    
    methods(Static = true, Access = private)
        function out = currentThis(in)
            persistent storedThis;
            if nargin
                storedThis = in;
            else
                out = storedThis;
            end
        end
        function assigner(data)
            fieldlist = fieldnames(data);
            for i = 1:length(fieldlist)
                assignin('caller',fieldlist{i},data.(fieldlist{i}))
            end
        end
    end
    
    events
        ComponentChanged
    end
end
