classdef ErrorOverrideMixin < handle
    %ERROROVERRIDEMIXIN Throws a custom error when unsupported functions are called by
    %property converter objects (UIControlPropertiesConverter,
    %ButtonGroupPropertiesConverter)

    % Override additional errors with new methods shadowing the unsupported
    % function. Ensure the message + hole (function name) provide a reasonable error.

    % Copyright 2023 The MathWorks, Inc.

    methods (Hidden)
        function uistack(obj, varargin)
            ME = MException(message('MATLAB:appdesigner:appdesigner:ConverterUnsupported', 'UISTACK'));
            throw(appdesigner.internal.appalert.TrimmedException(ME));
        end

        function findobj(obj, varargin)
            ME = MException(message('MATLAB:appdesigner:appdesigner:ConverterUnsupported', 'FINDOBJ'));
            throw(appdesigner.internal.appalert.TrimmedException(ME));
        end

        function findall(obj, varargin)
            ME = MException(message('MATLAB:appdesigner:appdesigner:ConverterUnsupported', 'FINDALL'));
            throw(appdesigner.internal.appalert.TrimmedException(ME));
        end
    end
end