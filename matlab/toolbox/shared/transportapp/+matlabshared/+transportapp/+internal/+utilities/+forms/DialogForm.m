classdef DialogForm
    %DIALOGFORM form class contains information about the title of the
    % warning, error, or options dialog box and their contents.

    % Copyright 2020 The MathWorks, Inc.

    properties
        % Title text of the dialog box
        Title (1, 1) string

        % The content to be displayed in the dialog box
        Message (1, 1) string
    end

    methods
        function obj = DialogForm(title,message)
            obj.Title = title;
            obj.Message = message;
        end
    end
end