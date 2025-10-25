classdef MATLABBlocker < handle
    %MATLABBLOCKER is used to block / unblock MATLAB execution

    % Copyright 2021 The MathWorks, Inc.
    properties
       WaitFlag
    end

    methods (Access = protected)
        function blockMATLAB(obj)
            waitfor(obj,'WaitFlag','stopWaiting');
        end
        
        function unblockMATLAB(obj)            
            obj.WaitFlag = 'stopWaiting';
        end
    end
end