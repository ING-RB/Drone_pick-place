% AbstractError - Used for formatting the error message in the Task/Request display

% Copyright 2012-2021 The MathWorks, Inc.

classdef (Hidden) AbstractError < parallel.internal.display.DisplayableItem & ...
        parallel.internal.display.StackDisplayMixin
    properties (SetAccess = immutable, GetAccess = private)
        Error
    end

    methods
        function obj = AbstractError(displayHelper, error)
            obj@parallel.internal.display.DisplayableItem(displayHelper);
            obj.Error = error;
        end

        function displayInMATLAB(obj, ~)
           import parallel.internal.display.DisplayableItem

            if isempty(obj.Error)
                msg = message('MATLAB:parallel:display:None');
                displayValue = msg.getString();
                obj.DisplayHelper.displayProperty('Error', displayValue, ...
                                                  DisplayableItem.DoNotFormatValue);
                return
            end
            errMessage = obj.DisplayHelper.wrapText(obj.Error.message);
            if ~isempty(obj.Error.stack)
                stackString = getStackCellStr(obj, obj.Error.stack, ...
                    obj.DisplayHelper.ShowLinks);
                errMessage = [errMessage(:)', stackString(:)'];
            end
            errMessage = obj.DisplayHelper.formatCellStr(errMessage);
            obj.DisplayHelper.displayProperty('Error', ...
                                              errMessage, ...
                                              DisplayableItem.DoNotFormatValue);
        end
    end
end
