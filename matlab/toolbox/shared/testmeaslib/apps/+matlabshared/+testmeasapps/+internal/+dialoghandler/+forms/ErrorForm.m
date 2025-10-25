classdef ErrorForm < matlabshared.testmeasapps.internal.dialoghandler.forms.BaseForm
    %ERRORFORM is the form class that contains information about the Error
    %Dialog that is to be shown in the app.

    %   Copyright 2021 The MathWorks, Inc.

    properties
        % The exception instance.
        Exception
    end

    properties (Constant)
        Type = "ErrorForm"
    end

    methods
        function obj = ErrorForm(varargin)
            switch nargin
                case 0
                    % Does nothing
                case 1
                    obj.Exception = varargin{1};
                case 2
                    obj.Title = varargin{1};
                    obj.Exception = varargin{2};
                otherwise
                    throwInvalidNarginError(obj);
            end
        end
    end
end

