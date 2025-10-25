classdef UserRichEditorUIType
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties
        Value
        RichEditorUI
    end
    
    methods
        function this = UserRichEditorUIType(value, varargin)
            this.Value = value;
            
            if nargin > 1
                this.RichEditorUI = varargin{1};
            end
        end
    end
end

