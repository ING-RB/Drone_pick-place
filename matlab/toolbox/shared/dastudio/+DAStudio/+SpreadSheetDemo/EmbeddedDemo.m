classdef EmbeddedDemo < DAStudio.SpreadSheetDemo.BaseDemo
    %EMBEDDEDSPREADSHEETDEMO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mDockPos;
        mDockMode;
    end
    
    methods
        function this = EmbeddedDemo(name, modelname)
            
            this = this@DAStudio.SpreadSheetDemo.BaseDemo();
            
            this.mDockPos = 'Bottom';
            this.mDockMode = 'stacked';
            
            editor = GLUE2.Util.findAllEditors(modelname);
            if ~isempty(editor)
                studio = editor.getStudio;
                this.mComponent = GLUE2.SpreadSheetComponent(studio, name);
                this.mComponentName = sprintf('GLUE2:SpreadSheet/%s', name);
                %this.mComponent.setColumns(this.mColumns);
                studio.registerComponent(this.mComponent);
                studio.moveComponentToDock(this.mComponent, name, ...
                    this.mDockPos,this.mDockMode);
                
                this.mComponent.onSelectionChange = ...
                    @DAStudio.SpreadSheetDemo.BaseDemo.handleSelectionChange;
                this.mComponent.onTabChange = ...
                    @DAStudio.SpreadSheetDemo.BaseDemo.handleTabChange;
            end
        end
        
%         function update(obj)
%             if ~isempty(obj.mComponent)
%                 obj.mComponent.setSource(obj);
%                 obj.mComponent.setColumns(obj.mColumns);
%             end
%         end
    end
    
end

