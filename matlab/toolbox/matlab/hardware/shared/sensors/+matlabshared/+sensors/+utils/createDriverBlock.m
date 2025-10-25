%   Copyright 2022 The MathWorks, Inc.
function obj = createDriverBlock(varargin)
% creates an object of class driverBlock  
p=inputParser;
addParameter(p,'Name','')
addParameter(p,'BlockType','')
addParameter(p,'Peripheral','')
parse(p,varargin{:})
Name = p.Results.Name;
BlockType = p.Results.BlockType;
Peripheral = p.Results.Peripheral;
obj = matlabshared.sensors.utils.driverBlock(Name,BlockType,Peripheral);
end
