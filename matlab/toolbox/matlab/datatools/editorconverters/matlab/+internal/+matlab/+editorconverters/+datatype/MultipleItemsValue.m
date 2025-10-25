classdef MultipleItemsValue
    % This class is used for the value of the items when the item is
    % can be multiple things         
    %
    % Ex: list box
    % Ex: not drop down    

    % Copyright 2017-2020 The MathWorks, Inc.

    properties(Access = private)
        Value;
    end

    methods
        function this = MultipleItemsValue(v)
            this.Value = v;
        end

        function v = getItems(this)
            v = this.Value;
        end
    end
end
