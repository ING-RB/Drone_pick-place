classdef AppDesignerSourceData < BindMode.BindModeSourceData
	% This class implements the abstract class BindModeSourceData to
	% provide the information required from App Designer User
	% Interface to enter Bind Mode to connect to blocks.

	% Copyright 2022 The MathWorks, Inc.

	properties (SetAccess = protected, GetAccess = public)
		modelName
		clientName = BindMode.ClientNameEnum.APPDESIGNER
		isGraphical = false
		modelLevelBinding = true
		sourceElementPath
		hierarchicalPathArray = {}
		sourceElementHandle
		allowMultipleConnections = false
		requiresDropDownMenu = false
		appdesignerBindModeHandler
	end

	methods
		function obj = AppDesignerSourceData (modelName, appdesignerBindModeHandler)
			obj.modelName = modelName;
			obj.appdesignerBindModeHandler = appdesignerBindModeHandler;
		end

		function bindableData = getBindableData(obj, selectionHandles, activeDropDownValue)
			bindableData = obj.appdesignerBindModeHandler.getBindableData(selectionHandles, activeDropDownValue);
		end

		function result = onRadioSelectionChange(obj, dropDownValue, bindableType, bindableName, bindableMetaData, isChecked)
			result = obj.appdesignerBindModeHandler.onRadioSelectionChange(dropDownValue, bindableType, bindableName, bindableMetaData, isChecked);
		end
	end
end
