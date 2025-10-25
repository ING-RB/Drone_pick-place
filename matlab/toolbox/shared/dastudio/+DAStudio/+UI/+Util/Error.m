classdef Error <handle
    % The type can be the following strings: 'Unknown', 'Error', 'Warning',
    % 'Info'
    % The color should be in the following format: [r, g, b, a], i.e [0, 100, 100, 100]
    properties
        ID = '';
        Tag = '';
        Type = 'Unknown';
        Message = '';
        HiliteColor = [];
        DisplayValue= '';
        Children = {};
    end
    
    methods
        function this = Error(varargin)
            if(nargin == 3)
                this.ID = varargin{1};
                this.Type = varargin{2};
                this.Message = varargin{3};
            elseif(nargin == 4)
                this.ID = varargin{1};
                this.Type = varargin{2};
                this.Message = varargin{3};
                this.HiliteColor = varargin{4};
            elseif( nargin == 5)
                this.ID = varargin{1};
                this.Tag = varargin{2};
                this.Type = varargin{3};
                this.Message = varargin{4};
                this.HiliteColor = varargin{5};
            end
        end  
    end    
end

