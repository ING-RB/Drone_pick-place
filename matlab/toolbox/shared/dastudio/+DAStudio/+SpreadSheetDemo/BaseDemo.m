classdef BaseDemo < handle
    %SPREADSHEETDEMO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mData;
        mComponentName;
        mColumns;
        mComponent;
        mTabs;
    end
    
    methods(Static)
        function result = handleSelectionChange(comp, sels)
            for i = 1:length(sels)
                str = sprintf('Selected: %s', sels{i}.getDisplayLabel());
                disp(str);
            end
            result = true;
        end
        
        function handleTabChange(comp, tabID)
            str = sprintf('Comp: %s\nTab ID: %d Selected', comp, tabID);
            disp(str);
        end
    end
    
    methods
        function this = BaseDemo()
            
            this.mData = [];
            this.mColumns = [];

        end
        
        function children = getChildren(obj, component)
            if ~isempty(obj.mData)
                % If children has been specified, just return the children
                children = obj.mData;
                return;
            else
                % If children has not been specified, create a default set
                % of children and return
                count = 1000;
                children = [];
                if obj.mUDD
                    children = cell(count);
                end
                if strcmp(component, obj.mComponentName)
                    if isempty(obj.mData)
                        obj.mData = cell(count);
                        for i = 1:count
                            itemName = sprintf('Item %d', i);
                            itemValue = sprintf('%d', i);
                            itemType = sprintf('Item %d Type', i);
                            % MCOS only
                            childObj = DAStudio.SampleSpreadSheetObjectMCOS(itemName, ...
                                itemValue, itemType);
                            children = [children childObj];
                        end
                        obj.mData = children;
                    end
                    children = obj.mData;
                end
            end
        end
        
        function columns = getColumns(obj)
            columns = obj.mColumns;
        end
        
        function comp = getComponent(obj)
            comp = obj.mComponent;
        end
        
        function update(obj)
            if ~isempty(obj.mComponent)
                obj.mComponent.setSource(obj);
                for idx = 1:length(obj.mTabs)
                    obj.mComponent.addTab(obj.mTabs(idx).tabTitle, obj.mTabs(idx).tabName, obj.mTabs(idx).tabDesc);
                end
                obj.mComponent.setColumns(obj.mColumns);
            end
        end
        
        function addTab(obj, tabTitle, tabName, tabDesc)
            
            thisTab = DAStudio.SpreadSheetDemo.Tab(tabTitle, tabName, tabDesc);
            obj.mTabs = [obj.mTabs thisTab];
            
        end
        
        function resolved = resolveSourceSelection(obj, selections, ~, ~)
            resolved = selections;
            if ~isempty(obj.mData)
                resolved = obj.mData(round(1 + (1000-1)*rand));
            end
        end
    end
    
end

