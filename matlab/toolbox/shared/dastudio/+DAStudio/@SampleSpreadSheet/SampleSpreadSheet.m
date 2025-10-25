classdef SampleSpreadSheet < handle
    properties
        mData;        
        mComponentName;
        mColumns;
        mComponent;
        % We have some special handling inside dastudio for this.
    end
    %
        methods(Static)
            function result = handleSelectionChange(comp, sels)
                for i = 1:length(sels)
                    str = sprintf('Selected: %s', sels{i}.getDisplayLabel());
                    disp(str);
                end
                result = true;
            end
        end
        methods(Static)
            function handleTabChange(comp, tabID)
                str = sprintf('Tab ID: %d Selected', tabID);
                disp(str);                
            end
        end
    methods
        function this = SampleSpreadSheet(name, modelname)
            this.mData = [];            
            if isempty(name)
                name = 'Sample';
            end            
            this.mComponentName = sprintf('GLUE2:SpreadSheet/%s', name);
            this.mColumns = {'Prop1', 'Prop2', 'Prop3'};
            if nargin == 2
                editor = GLUE2.Util.findAllEditors(modelname);              
                if ~isempty(editor)
                    studio = editor.getStudio;
                    this.mComponent = GLUE2.SpreadSheetComponent(studio, name);
                    this.mComponent.setColumns(this.mColumns);
                    studio.registerComponent(this.mComponent);
                    studio.moveComponentToDock(this.mComponent, name, ...
                        'Bottom','stacked');
                    this.mComponent.onSelectionChange = ...
                        @SampleSpreadSheet.handleSelectionChange;                     
                    this.mComponent.onTabChange = ...
                        @SampleSpreadSheet.handleTabChange;
                end
            else
                % Standalone
                this.mComponent = GLUE2.SpreadSheetComponent(name);
                this.mComponent.setColumns(this.mColumns);
                this.mComponent.show
            end            
        end        
        %
        function children = getChildren(obj, component)            
           count = 1000;
           children = [];           
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
        %
        function columns = getColumns(obj)
            columns = obj.mColumns;
        end
        %
        function comp = getComponent(obj)
            comp = obj.mComponent;
        end
        %
        function update(obj)            
            if ~isempty(obj.mComponent)
                obj.mComponent.setSource(obj);                
            end
        end
        function resolved = resolveSourceSelection(obj, selections)
            resolved = selections;
            if ~isempty(obj.mData)
                resolved = obj.mData(round(1 + (1000-1)*rand));
            end
        end
    end
end
