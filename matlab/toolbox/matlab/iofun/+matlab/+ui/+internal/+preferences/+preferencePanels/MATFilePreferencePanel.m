classdef MATFilePreferencePanel < handle
    %MATFILEPREFERENCEPANEL The preference panel for MATLAB save format
    %   The class describing the MATLAB General MAT-Files Preferences pane
    %   in Preferences window.

%   Copyright 2020 The MathWorks, Inc.
    
    properties (Access = public)
        UIFigure;
        SaveFormatButtonGroup;
    end
    
    methods (Access = public)
        % Constructor
        function obj = MATFilePreferencePanel()
            %MATFILEPREFERENCEPANEL Construct an instance of this class
            
            % Create uiFigure
            obj.UIFigure = uifigure;
            
            % Create grid
            figGrid = uigridlayout(obj.UIFigure, [3 1], 'Scrollable', 'on', ...
                'RowHeight', {'fit',165,'fit'}, 'ColumnWidth', {540});
            
            % Create label
            uilabel(figGrid, ...
                'Text', getTextString('MATLAB:MatFile:SaveFormatTitle'), ...
			    'FontWeight', 'bold');
            
            % Create buttons
            obj.SaveFormatButtonGroup = uibuttongroup(figGrid, ...
                'Title', getTextString('MATLAB:MatFile:SaveFormatButtonGroupTitle'), ...
                'Visible', 'off');

            s = settings;
            saveFormat = s.matlab.general.matfile.SaveFormat;

            uiradiobutton(obj.SaveFormatButtonGroup, ...
                'Text', getTextString('MATLAB:MatFile:Version_7_3_Button'), ...
                'Position', [12 95 450 30], ...
                'Value', strcmp(saveFormat.ActiveValue, 'v7.3'));
            uiradiobutton(obj.SaveFormatButtonGroup, ...
                'Text', getTextString('MATLAB:MatFile:Version_7_Button'), ...
                'Position', [12 55 450 30], ...
                'Value', strcmp(saveFormat.ActiveValue, 'v7')); % the default
            uiradiobutton(obj.SaveFormatButtonGroup, ...
                'Text', getTextString('MATLAB:MatFile:Version_5_Button'), ...
                'Position', [12 15 450 30],...
                'Value', strcmp(saveFormat.ActiveValue, 'v6'));

            % Make the SaveFormatButtonGroup visible after creating child objects. 
            obj.SaveFormatButtonGroup.Visible = 'on';
            
            % Create bottom label
            uilabel(figGrid, 'Text', ...
                getString(message('MATLAB:MatFile:FIG_Note')));
        end
         
        function result = commit(obj)
            try
                % Save the preferences
                s = settings;
                
                if (obj.SaveFormatButtonGroup.Buttons(1).Value == true)
                    s.matlab.general.matfile.SaveFormat.PersonalValue = 'v7.3';
                elseif (obj.SaveFormatButtonGroup.Buttons(2).Value == true)
                    s.matlab.general.matfile.SaveFormat.PersonalValue = 'v7';
                else 
                    assert(obj.SaveFormatButtonGroup.Buttons(3).Value == true);
                    s.matlab.general.matfile.SaveFormat.PersonalValue = 'v6';
                end
                    
                result = true;                 
            catch ME
                result = false;
            end
        end
         
        function delete(obj)
            delete(obj.UIFigure);
        end
    end
end

function str = getTextString(id, varargin)
    % Reads strings from the resource bundle
    str = getString(message(id, varargin{:}));
end

