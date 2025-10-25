classdef DurationType < coder.type.Base
    % Custom coder type for duration
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
       Format
    end

    methods (Static, Hidden)
        function m = map()
            m.Format = {'fmt',@(obj,val,access)...
                obj.setTypeProperty('Format','Properties.fmt', ...
                obj.validateFormat(val,access), access)};
        end

        function resize = supportsCoderResize()
            resize.supported = true;
            resize.property = 'Properties.millis';
        end

        function x = validateFormat(x,access)
            if isempty(access)
                if isa(x, 'coder.Constant')
                    matlab.internal.coder.duration.verifyFormat(convertStringsToChars(x.Value));
                else
                    if ~matlab.internal.coder.type.util.isCharRowType(x) ...
                            && ~matlab.internal.coder.type.util.isScalarStringType(x)
                        error(message('MATLAB:duration:InvalidFormat'));
                    end
                end
            end
        end
    end
end
