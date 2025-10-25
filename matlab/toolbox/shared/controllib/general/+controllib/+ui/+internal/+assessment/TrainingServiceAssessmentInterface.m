classdef TrainingServiceAssessmentInterface < handle
    % Interface class to enable assessment API for training service.
    %
    % To provide consistent assessment API of control design tools to
    % training service, your App class must inherit from the
    % TrainingServiceAssessmentInterface class, which acts as an interface.
    %
    % In your subclass, you must implement the "hasVariableInWorkspace" and
    % "getVariableFromWorkspace" methods required by the interface.
    
    % Copyright 2023 The MathWorks, Inc.
    
    events
        % Currently, there is no available events defined.
        %
        % ToDo: Define events as needed to use the Assessment API with Apps
    end
    
    methods (Abstract, Hidden)
        % Method "hasVariableInWorkspace": 
        %
        %   Implement this method to return a boolean whether a variable
        %   exists in a specific workspace.
        %
        %       hasVariable = hasVariableInWorkspace(this, varname, wksname)
        %
        %   "varname" is the name of the requested variable (a char array).
        %
        %   "wksname" is the name of the specific workspace (a char array).
        %
        %   "hasVariable" should be a boolean.
        hasVariableInWorkspace(this, varname, wksname) 
        % Method "getVariableFromWorkspace": 
        %
        %   Implement this method to return the data object in a specific
        %   workspace.
        %
        %       data = getVariableFromWorkspace(this, varname, wksname)
        %
        %   "varname" is the name of the requested variable (a char array).
        %
        %   "wksname" is the name of the specific workspace (a char array).
        %
        %   "data" should be a data object.
        getVariableFromWorkspace(this, varname, wksname)
    end

    methods (Access = protected)
        % Method "getExistingVarListFromWorkspace"
        %
        % Helper method to find all existing variable names from the
        % specified workspace. 
        % 
        %       varlist = getExistingVarListFromWorkspace(this, wksObj)   
        %
        %   "wksObj" can either be a workspace object from the class
        %   matlab.internal.datatoolsservices.AppWorkspace or "base" for
        %   the MATLAB workspace
        %   
        %   "varlist" is a cell array including all variable names in the
        %   specified workspace
        % 
        function varlist = getExistingVarListFromWorkspace(this, wksObj)
            if (isstring(wksObj) && isequal(wksObj,"base")) ...
                    || (ischar(wksObj) && isequal(wksObj,'base'))
                varlist = evalin("base","who");
            elseif isa(wksObj, "matlab.internal.datatoolsservices.AppWorkspace")
                varlist = wksObj.evalin("who");
            else
                varlist = '';
            end
        end
    end
    
end

