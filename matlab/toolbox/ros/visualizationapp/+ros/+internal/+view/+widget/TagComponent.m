classdef TagComponent < matlab.ui.componentcontainer.ComponentContainer
    % TagComponent 
    properties
        Value  = 'Tag';
        %DeleteButtonCallback = function_handle.empty;
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        DeleteButtonClicked % ValueChangedFcn callback property will be generated
    end

    properties (Access = ?matlab.unittest.TestCase, Transient, NonCopyable)
        NumericField (1,1) matlab.ui.control.NumericEditField
        GridLayout matlab.ui.container.GridLayout
        LabelObj matlab.ui.control.Label
        DeleteButton matlab.ui.control.Button
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        TagDeleteButtonTag = 'rosbagViewerTagComponentDeleteButtonTag';
    end

    methods (Access=protected)
        function setup(obj)
            % Set the initial position of this component
            obj.Position = [100 100 150 22];

            % Layout
            obj.GridLayout = uigridlayout(obj,[1,5], ...
                'RowHeight', {22}, 'ColumnWidth', {'fit', 'fit'},...
                'Padding', 0, 'ColumnSpacing', 2);
            if strcmp(obj.GridLayout.Parent.Parent.Parent.Parent.Theme, 'light')
                obj.GridLayout.BackgroundColor = [1 1 1];
            end
            obj.LabelObj = uilabel(obj.GridLayout);

            obj.DeleteButton = uibutton(obj.GridLayout, "Tag", obj.TagDeleteButtonTag);
            matlab.ui.control.internal.specifyIconID(obj.DeleteButton, 'delete', 16);
            obj.DeleteButton.Text = '';
            %obj.DeleteButton.ButtonPushedFcn = obj.DeleteButtonCallback;

            obj.DeleteButton.ButtonPushedFcn = @(~, ~)obj.deleteTagCallback();
        end

        function update(obj)
            % Update view
            obj.LabelObj.Text = obj.Value;
        end
    end

    methods (Access=private)
        function deleteTagCallback(obj)
            obj.notify("DeleteButtonClicked");
        end
    end
end
