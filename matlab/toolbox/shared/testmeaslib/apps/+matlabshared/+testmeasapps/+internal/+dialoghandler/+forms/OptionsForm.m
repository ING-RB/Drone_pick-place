classdef OptionsForm < matlabshared.testmeasapps.internal.dialoghandler.forms.BaseForm
    %OPTIONSFORM class contains information about the Options Dialog to be
    %constructed.

    % Copyright 2021 The MathWorks, Inc.

    properties (Constant)
        Type = "OptionsForm"
    end

    properties
        Message (1, 1) string

        % The options that users can select in the Options Dialog box, e.g.
        % "OK" and "Cancel"
        Options (1, 2) string

        % The default option selected.
        DefaultOption (1, 1) string
    end

    %% Lifetime
    methods
        function obj = OptionsForm(varargin)

            switch nargin
                case 0
                    % Does nothing
                case 3
                    obj.Message = varargin{1};
                    obj.Options = varargin{2};
                    obj.DefaultOption = varargin{3};
                case 4
                    obj.Title = varargin{1};
                    obj.Message = varargin{2};
                    obj.Options = varargin{3};
                    obj.DefaultOption = varargin{4};
                otherwise
                    throwInvalidNarginError(obj);
            end
        end
    end
end