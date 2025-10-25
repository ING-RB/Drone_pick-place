% This class is unsupported and might change or be removed without
% notice in a future version.

classdef GraphicsMetaData < internal.matlab.inspector.InspectorMetaData
    % This class represents metadata for graphics hierarchy
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties (Access = private)
        Token
    end
    
    methods
        
        function this = GraphicsMetaData(hObj)
            if isa(hObj,'internal.matlab.inspector.InspectorProxyMixin')
                hObj = hObj.OriginalObjects;
            end        
            this.RefObject = hObj;                   
            this.Token = local_getCurrentToken(this.RefObject);
           
            if ~isempty(this.RefObject)
                data = this.getCurrentData();
                this.BreadCrumbsData = data.BreadCrumbsData;
                this.TreeData =  data.TreeData;
            end
        end
                                
        function forceTreeDataRefresh(this)
            data = this.getCurrentData();
            this.TreeData = data.TreeData;


        end
        
        % Returns true if the metadata has changed
        function changed = hasDataChanged(this)
            changed = false;
           
            % if nothing changed in the figure - early return
            if this.Token == local_getCurrentToken(this.RefObject)
                return
            end
                                   
            this.Token = local_getCurrentToken(this.RefObject);            
            data = this.getCurrentData();
            
            newBreadCrumbsData = data.BreadCrumbsData;
            
            if ~isequal(newBreadCrumbsData,this.BreadCrumbsData)
                this.BreadCrumbsData = newBreadCrumbsData;
                changed = true;
            end
            
            newTreeTreeData = data.TreeData;
            
            if ~isequal(newTreeTreeData,this.TreeData)
                this.TreeData = newTreeTreeData;
                changed = true;
            end
        end
        
        % Returns the meta data
        function data = getData(this)
            % make sure to always return the most updated data
            this.hasDataChanged();
            data = struct('treeData', {this.TreeData},'breadCrumbsData',{this.BreadCrumbsData});            
        end
    end
    
    methods (Hidden)        
        function d = getCurrentData(this)
             d.BreadCrumbsData = matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.getBreadCrumbsData(this.RefObject);
             d.TreeData = matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.getTreeData(this.RefObject);
        end
    end                
end

function token = local_getCurrentToken(hObj)
if ~isscalar(hObj)
    % matlab.mixin.internal.Scalar - does not allow indexing g1981504
    hObj = hObj(1);    
end
token = get(ancestor(hObj,'figure'),'UpdateToken');
end




