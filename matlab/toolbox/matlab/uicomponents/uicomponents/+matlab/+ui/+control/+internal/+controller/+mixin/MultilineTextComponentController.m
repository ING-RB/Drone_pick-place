classdef (Hidden) MultilineTextComponentController <  appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % Mixin Controller Class for Multiline Text Components

    % Copyright 2011-2021 The MathWorks, Inc.

    methods

        function viewPvPairs = getTextPropertiesForView(obj, propertyNames)
            % Gets all properties for view based on 'Text'
            import appdesservices.internal.util.ismemberForStringArrays;
            import matlab.ui.control.internal.controller.mixin.MultilineTextComponentController.formatTextData;
            viewPvPairs = {};

            if(ismemberForStringArrays("Text", propertyNames))
                modelData = obj.Model.Text;
                modelData = formatTextData(modelData);
                viewPvPairs = [viewPvPairs, ...
                    {'Text', modelData} ...
                    ];
            end
        end
    end
    methods(Access = 'protected')
        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)

            if(isfield(changedPropertiesStruct, 'Text'))
                newText = changedPropertiesStruct.Text;

                % some parts of the client (specifically the Inspector in
                % this case) can send [] when the user typed in a blank
                % value
                %
                % Want to explicitly convert to ''
                %
                % This could be removed if Inspector is no longer going
                % through controllers to update properties.
                %
                % g1475502
                if(isempty(newText))
                    newText = '';
                end

                obj.Model.Text = newText;

                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'Text');
            end
        end
    end

    methods(Static)
        function modelData = formatTextData(modelData)
            if ~iscell(modelData)
                modelData = regexp(modelData,'\n','split'); %split into muliple arrays for each line of text
            end
        end
    end
end

