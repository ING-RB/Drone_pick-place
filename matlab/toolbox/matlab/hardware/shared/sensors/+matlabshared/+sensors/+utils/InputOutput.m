%   Copyright 2022 The MathWorks, Inc.
classdef InputOutput < matlab.mixin.SetGet
%     InputOutput creates an entity of type Input or Output which is assigned as a property of
%     driverBlock object which is used to create a sensor block.
%     Example:
%     h = InputOutput(inputName,varargin{:});
%     h = InputOutput('accelration','Datatype','double','Size',[1,3]);
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
        function obj = InputOutput(name,varargin)
            p = inputParser;
            addRequired(p,'name',@isvarname);
            addParameter(p,'Size',1);
            addParameter(p,'Label',name,@isstring);
            addParameter(p,'DataType','double',@ischar);
            parse(p,name,varargin{:});
            classes = {'numeric'};
            attributes = {'row','nonempty'};
            validateattributes(p.Results.Size,classes,attributes,'','Size');
            if(numel(p.Results.Size)>2)
                error(message('matlab_sensors:blockcreation:InputSize').getString);
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