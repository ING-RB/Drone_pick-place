function out = getSupportedHardwareBoards(varargin)
% getSupportedHardwareBoards - Return all boards supported by Robot
% Operating System (ROS) app.

% Copyright 2019-2024 The MathWorks, Inc.

productIDEnum = codertarget.targethardware.BaseProductID.ROS; 
if nargin > 0 && isequal(varargin{1}, 'matlab')
    % MATLAB registered hardware boards: ROS, ROS 2
    out = {};
    allHwBoards = codertarget.targethardware.getRegisteredTargetHardware('matlab');
    for i=1:numel(allHwBoards)
        if isequal(allHwBoards(i).BaseProductID, productIDEnum)
            out{end+1} = allHwBoards(i).DisplayName;
        end
    end
else
    % Simulink registered hardware boards: ROS, ROS 2, Raspi-ROS
    out = codertarget.targethardware.getSupportedHardwareBoardsForID(...
        productIDEnum);
end
