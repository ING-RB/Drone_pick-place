%   Copyright 2022 The MathWorks, Inc.
classdef Input < matlab.mixin.SetGet
    properties
        Name = '';
        DataType = 'double';
        Size = '';
        Label = '';

    end
    properties (Hidden)
        DefaultValue = '0';
    end
    methods
        function obj = Input(name,varargin)


            p = inputParser;
            addRequired(p,'name',@isvarname);
            addParameter(p,'Size',1);
            addParameter(p,'Label',name,@isstring);
            addParameter(p,'DataType','double',@ischar);

            parse(p,name,varargin{:});

            classes = {'numeric'};
            attributes = {'row','nonempty'};
            validateattributes(p.Results.Size,classes,attributes);

            if(numel(p.Results.Size)>2)
                error('expected [1x1] or [1x2] vector in size parameter')
            end
            obj.Name = convertStringsToChars(p.Results.name);
            obj.Label = convertStringsToChars(p.Results.Label);
            obj.DataType = convertStringsToChars(p.Results.DataType);
            if(numel(p.Results.Size)==1)
                obj.Size = sprintf('[%s,%s]',num2str(p.Results.Size),num2str(p.Results.Size));
            else
                obj.Size = sprintf('[%s,%s]',num2str(p.Results.Size(1)),...
                    num2str(p.Results.Size(2)));
            end

        end
    end
end