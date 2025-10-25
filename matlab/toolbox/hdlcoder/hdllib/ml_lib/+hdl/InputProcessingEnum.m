classdef InputProcessingEnum < Simulink.IntEnumType
    % Input processing mode for hdl.Delay
    enumeration
        FrameBasedProcessing(1)
        SampleBasedProcessing(2)
    end
end

