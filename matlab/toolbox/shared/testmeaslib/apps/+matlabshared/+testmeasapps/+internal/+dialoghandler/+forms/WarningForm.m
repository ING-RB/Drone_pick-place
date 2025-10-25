classdef WarningForm < matlabshared.testmeasapps.internal.dialoghandler.forms.BaseForm
    %DIALOGFORM form class contains information about the Warning Dialog to be
    %constructed.

    % Copyright 2021 The MathWorks, Inc.

    properties (Constant)
        Type = "WarningForm"
    end

    properties
        % Warning message identifier.
        %
        % NOTE - This is NOT used internally to display the warning
        % message, but can be used for verification of the warning message
        % id. Only the "Message" property gets used for displaying the
        % warning message in a dialog.
        Identifier (1, 1) string

        % The content to be displayed in the dialog box.
        Message (1, 1) string
    end

    methods
        function obj = WarningForm(varargin)

            switch nargin
                case 0
                    % Does nothing
                case 2
                    obj.Identifier = varargin{1};
                    obj.Message = varargin{2};
                case 3
                    obj.Title = varargin{1};
                    obj.Identifier = varargin{2};
                    obj.Message = varargin{3};
                otherwise
                    throwInvalidNarginError(obj);
            end
        end
    end
end