classdef WindowPreferencePanel < handle
%

%   Copyright 2023 The MathWorks, Inc.

    properties (Access = public)
        UIFigure;
        CheckBox;
    end

    methods (Access = public)
        % Constructor
        function obj = WindowPreferencePanel()
            s = settings;
            preferenceValue = s.matlab.general.windows.AutoCollapse.ActiveValue;
            
            % Create uiFigure
            obj.UIFigure = uifigure;
            
            % Create grid
            figGrid = uigridlayout(obj.UIFigure);
            figGrid.RowHeight = {'fit', 'fit'};
            figGrid.ColumnWidth = {'fit', 'fit'};
            
            % Create label
            label = uilabel(figGrid);
            label.Text = getString(message('MATLAB:windowmanagement:WinManageTitle'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            
            obj.CheckBox = uicheckbox(figGrid);
            obj.CheckBox.Text = getString(message('MATLAB:windowmanagement:AutoCollapseLabel'));
            obj.CheckBox.Value = preferenceValue;
            obj.CheckBox.Layout.Row = 2;
            obj.CheckBox.Layout.Column = 1;
           
        end
         
        function result = commit(obj)
             try
                % Save the preferences
                 s = settings;
                 s.matlab.general.windows.AutoCollapse.PersonalValue = obj.CheckBox.Value;
                result = true;                
            catch ME
                result = false;
            end
        end

        function delete(obj)
            delete(obj.UIFigure);
        end
    end

    methods(Static)
        function result = shouldShow()
            % Determines whether to show or hide the panel
            import matlab.internal.capability.Capability;
            result = ~Capability.isSupported(Capability.LocalClient);
        end
    end
end
