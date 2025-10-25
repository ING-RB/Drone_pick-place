%   Copyright 2022 The MathWorks, Inc.
classdef Property < matlab.mixin.SetGet
    %     Property creates an property entity used as property of sensor block(Block mask), which is assigned as a property of
    %     driverBlock object which is used to create a sensor block.
    %     Example:
    %     h = Property(inputName,varargin{:});
    %     h = Property('SensorPowerMode','Datatype','string','Tunable',true);
    properties
        Name = '';
        Size = '';
        DataType = '';
        Label = '';
        InitValue;
        Tunable;
        Visible;
        Enable;
    end
    methods
        function obj = Property(name,varargin)


            p = inputParser;
            addRequired(p,'name',@isvarname);
            addParameter(p,'Size',1);
            addParameter(p,'Label',name,@isstring);
            addParameter(p,'DataType','double',@ischar);
            addParameter(p,'Tunable',true,@islogical);
            addParameter(p,'Visible',true,@islogical);
            addParameter(p,'Enable',false,@islogical);
            addParameter(p,'InitValue','0');
            p.parse(name,varargin{:});
            classes = {'numeric'};
            attributes = {'row','nonempty'};
            validateattributes(p.Results.Size,classes,attributes);

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
            obj.InitValue = num2str(p.Results.InitValue);
            obj.Tunable = p.Results.Tunable;
            obj.Visible = p.Results.Visible;
            obj.Enable = p.Results.Enable;
        end
    end
end