classdef Manager < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber
    %MANAGER class creates and maintains the Code Log section for the app.

    % Copyright 2021 The MathWorks, Inc.

    properties
        % The handle to the UIHTML instance on which the editor is to be
        % rendered.
        UIHTMLHandle
    end

    properties (Constant)
        Constants = matlabshared.transportapp.internal.appspace.codelog.Constants
    end

    %% Lifetime
    methods
        function obj = Manager(form)
            arguments
                form matlabshared.transportapp.internal.utilities.forms.AppSpaceForm
            end
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory

            obj@matlabshared.mediator.internal.Subscriber(form.Mediator);
            obj@matlabshared.mediator.internal.Publisher(form.Mediator);
            parentGridLayout = AppSpaceElementsFactory.createGridLayout ...
                (form.Parent, obj.Constants.CodeLogGrid);

            obj.UIHTMLHandle = AppSpaceElementsFactory.createUIHTML ...
                (parentGridLayout, obj.Constants.CodeLogLayout, struct.empty);
        end
    end

    %% Implementing Subscriber Abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('EditorURL', ...
                @(src, event)obj.setEditorURL(event.AffectedObject.EditorURL));
        end
    end

    %% Subscriber callback function
    methods (Access = private)
        function setEditorURL(obj, editorURL)
            obj.UIHTMLHandle.HTMLSource = editorURL;
        end
    end
end