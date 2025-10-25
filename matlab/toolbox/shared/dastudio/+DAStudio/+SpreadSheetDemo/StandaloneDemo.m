classdef StandaloneDemo < DAStudio.SpreadSheetDemo.BaseDemo
    %STANDALONESPREADSHEETDEMO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = StandaloneDemo(name)
            
            this = this@DAStudio.SpreadSheetDemo.BaseDemo();
            
            this.mComponent = GLUE2.SpreadSheetComponent(name);
            this.mComponentName = sprintf('GLUE2:SpreadSheet/%s', name);
            %this.mComponent.setColumns(this.mColumns);
%             this.mComponent.addTab('Tab1', 'aa');
%             this.mComponent.addTab('Tab2', 'bb');

            this.mComponent.onSelectionChange = ...
                @DAStudio.SpreadSheetDemo.BaseDemo.handleSelectionChange;
            this.mComponent.onTabChange = ...
                @DAStudio.SpreadSheetDemo.BaseDemo.handleTabChange;
            
            this.mComponent.show;
        end
        
%         function update(obj)
%             if ~isempty(obj.mComponent)
%                 obj.mComponent.setSource(obj);
%                 obj.mComponent.setColumns(obj.mColumns);
%             end
%         end
        
    end
    
end

