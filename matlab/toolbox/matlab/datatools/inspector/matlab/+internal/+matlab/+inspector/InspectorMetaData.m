% This class is unsupported and might change or be removed without
% notice in a future version.

classdef InspectorMetaData < handle
    % This class is an interface for managing metadata of a given object in the
    % Inspector
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        % The reference object for the hierarchy.  This is the top level object
        % in the tree.
        RefObject
        
        % The breadcrumbs data for the object hierarchy
        BreadCrumbsData cell
        
        % The tree data for the object hierarchy
        TreeData cell

        VariableName
        VariableWorkspace
    end
    
    methods (Abstract)
        % Returns true if the metadata has changed
        hasDataChanged(obj)
        % Returns the current metadata
        getData(obj)
    end
end

