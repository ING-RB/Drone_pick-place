classdef OverrunActions < int32
    %OverrunActions Enumeration for rateControl overrun actions
    %   OverrunActions enumerates the overrun actions supported by 
    %   rateControl, which currently includes Drop and Slip.
    %
    %   See also rateControl.
    
    %   Copyright 2015-2024 The MathWorks, Inc.
    
    enumeration
        %Drop - 'drop' OverrunAction for rateControl
        Drop(1)
        
        %Slip - 'slip' OverrunAction for rateControl
        Slip(2)
    end
end
