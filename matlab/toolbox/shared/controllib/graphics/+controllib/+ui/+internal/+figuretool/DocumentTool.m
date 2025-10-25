classdef DocumentTool < controllib.ui.internal.figuretool.AbstractTool
% DocumentTool is the super-class of your DocumentTool subclass.

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Access = protected)
        
        function this = DocumentTool(tag, varargin)
            this = this@controllib.ui.internal.figuretool.AbstractTool(tag, varargin{:});
        end

    end
    
end