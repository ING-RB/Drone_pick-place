classdef HasOutputStreamMixin < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (Dependent, Hidden, GetAccess = protected, SetAccess = immutable)
        OutputStream (1,1) matlab.automation.streams.OutputStream
    end
    
    properties (Access = private)
        InternalOutputStream matlab.automation.streams.OutputStream {mustBeScalarOrEmpty}
    end
    
    methods
        function stream = get.OutputStream(mixin)
            import matlab.automation.streams.ToStandardOutput;
            stream = mixin.InternalOutputStream;
            if isempty(stream)
                stream = ToStandardOutput();
                mixin.InternalOutputStream = stream;
            end
        end
    end
    
    methods (Hidden, Access = protected)
        function mixin = HasOutputStreamMixin(stream)
            arguments
                stream matlab.automation.streams.OutputStream {mustBeScalarOrEmpty} = matlab.automation.streams.OutputStream.empty()
            end
            mixin.InternalOutputStream = stream;
        end
    end
end

