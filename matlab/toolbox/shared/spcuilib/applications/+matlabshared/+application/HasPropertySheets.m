classdef HasPropertySheets < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (Hidden, SetAccess = protected)
        CurrentPropertySheet
        AllPropertySheets = matlabshared.application.PropertySheet.empty;
    end
    
    methods
        
        function set.CurrentPropertySheet(this, sheet)
            oldSheet = this.CurrentPropertySheet;
            if ~isempty(oldSheet)
                oldSheet.Visible = false;
            end
            this.CurrentPropertySheet = sheet;
            sheet.Visible = true;
            onPropertySheetChanged(this, oldSheet);
        end
        
        function oldSheet = update(this, controller)
            if isempty(controller)
                % Use the Arbitrary Sheet as a default
                c = this.getDefaultPropertySheet;
            else
                c = getPropertySheetConstructor(controller);
            end
                        
            oldSheet = this.CurrentPropertySheet;
            if isa(oldSheet, c)
                sheet = oldSheet;
                sheet.Visible = true;
            else
                sheet = findobj(this.AllPropertySheets, '-class', c);
                if isempty(sheet)
                    sheet = feval(c, this);
                    this.AllPropertySheets(end+1) = sheet;
                end
                this.CurrentPropertySheet = sheet;
            end
            update(sheet);
        end
    end
    
    methods (Access = protected)
        function onPropertySheetChanged(~, ~)
            % NO OP
        end
    end
    
    methods (Abstract)
        sheet = getDefaultPropertySheet
    end
end

% [EOF]
