classdef FontSize < internal.matlab.editorconverters.datatype.EditableStringEnumeration
    % FontSize - datatype used to represent the font size for an object.  It
    % displays as an editable dropdown.
    
    % Copyright 2021 The MathWorks, Inc.

    properties(Constant)
        % This is the same list as is used in
        % matlab.ui.internal.dialog.FontChooser
        DEFAULT_FONT_SIZES = [8, 9, 10, 12, 14, 18, 24, 36, 48];
    end
    
    methods
        function this = FontSize(val)
            this@internal.matlab.editorconverters.datatype.EditableStringEnumeration(val);
            this.Value = string(val);

            fontSizes = this.getSizes(val);
            this.EnumeratedValues = cellstr(string(fontSizes));
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end

    methods(Access = private)
        function fs = getSizes(this, newSize)
            persistent fontSizes;

            if isempty(fontSizes)
                fontSizes = this.DEFAULT_FONT_SIZES;
            end
            
            if ~isnumeric(newSize)
                newSize = str2double(newSize);
            end

            newFontSizes = sort(unique([newSize, fontSizes]));
            fontSizes = newFontSizes;
            fs = fontSizes;
        end
    end
end
