classdef EventStatus < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for reading click, freefall, inertial wakeup, 6d position, 4d position, 6d movement and 4d movement status from LIS3DH.
    %freefall, inertial wakeup, 6d position, 4d position, 6d movement and 4d movement are grouped together as event1 and event2
    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = [1,3]
        OutputName = 'Click axis [X, Y, Z]' %Default name
        IsOutputComplex = false
        OutputDataType = 'uint8'
        Event = 'click' %Possible values are Click, Event1 or Event2
    end

    methods
        function [data,timestamp] = readSensorImpl(obj, sensorObj)
            [data,timestamp] = readEventStatus(sensorObj,obj.Event);
        end
    end
end