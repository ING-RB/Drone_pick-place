classdef VariableSelectorTC < toolpack.AtomicComponent
    %
    
    %VARIABLESELECTORTC
    %
    %    Tool component to select variables from a list of known variables.
    %
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = private)
        CandidateVariables  %List of candidate variables
    end
    
    methods(Access = public)
        function obj = VariableSelectorTC(vars)
            %VARIABLESELECTORTC Construct VariableSelector Tool component
            %
            
            obj = obj@toolpack.AtomicComponent;
            obj.Database = [];
            
            if nargin > 0
                setCandidateVariables(obj,vars)
            else
                setCandidateVariables(obj,cell(0,4));
            end
        end
        function setCandidateVariables(this,data)
            %SETCANDIDATEVARIABLES
            %
            
            if iscell(data) && ismatrix(data) && size(data,2) == 4
                this.CandidateVariables = data;
            else
                error(message('Controllib:gui:errVariableSelector_CandidateVariables'));
            end
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            %CREATEVIEW Construct graphical component for the tool component
            %
            view = ctrluis.paramtable.VariableSelectorGC(this);
        end
    end
    methods(Access = protected)
        function mUpdate(this) %#ok<MANU>
            %MUPDATE Perform subclass specific updates
            %
        end
    end
end
