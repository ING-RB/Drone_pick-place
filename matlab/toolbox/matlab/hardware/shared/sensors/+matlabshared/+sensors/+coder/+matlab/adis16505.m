classdef adis16505
    % codegen redirect class for adis16505

    %   Copyright 2024 The MathWorks, Inc

    %#codegen
    methods(Static)
        function [taps,argumentsForInit] = getParsedArguments(varargin)
            narginchk(1,8);
            parms = struct('SPIChipSelectPin','0','NumTapsBartlettFilter',1, 'Bus', uint32(0),...
                'SampleRate', uint32(0), 'SamplesPerRead', uint32(0),...
                'ReadMode', uint32(0),...
                'OutputFormat', uint32(0), 'TimeFormat', uint32(0));
            poptions = struct('CaseSensitivity',false,'PartialMatching','unique','StructExpand',false);
            pstruct = coder.internal.parseParameterInputs(parms,poptions,varargin{1:end});
            taps = coder.internal.getParameterValue(pstruct.NumTapsBartlettFilter, 1, varargin{1:end});
            cspin = coder.internal.getParameterValue(pstruct.SPIChipSelectPin, '0', varargin{1:end});
            sampleRate = coder.internal.getParameterValue(pstruct.SampleRate,uint32(0), varargin{1:end});
            if ~isscalar(taps) && ~ismember(taps,[1,2,4,8,16,32,64])
                error(message('matlab_sensors:general:InvalidTapValue'));
            end
            argumentsForInit = {'SPIChipSelectPin',cspin,'SampleRate',sampleRate};
        end
    end
end

