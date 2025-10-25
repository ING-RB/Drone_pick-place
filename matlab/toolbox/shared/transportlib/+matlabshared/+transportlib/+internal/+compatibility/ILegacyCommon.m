classdef (Abstract, Hidden) ILegacyCommon < handle
    %ILEGACYCOMMON Legacy methods common to all interfaces.

    % Copyright 2021 The MathWorks, Inc.

    %% Legacy Methods
    methods (Abstract, Hidden)
        % FOPEN
        fopen(obj)

        % FCLOSE
        fclose(obj)

        % FLUSHINPUT
        flushinput(obj)

        % FLUSHOUTPUT
        flushoutput(obj)
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = ILegacyCommon
            coder.allowpcode('plain');
        end
    end
end

