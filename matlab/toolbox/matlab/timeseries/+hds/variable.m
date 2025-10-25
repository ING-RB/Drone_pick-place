classdef variable < matlab.mixin.SetGet & matlab.mixin.Copyable
    %   This class is for internal use only and will be removed in a later
    %   release.
    properties (SetAccess=protected, SetObservable)
        Name = '';
    end
    methods  % constructor block
        function this = variable(var,~)
        end  % variable
    end  % constructor block

    methods
        function set.Name(obj,value)
            % DataType = 'string'
            validateattributes(value,{'char'}, {'row'},'','Name')
            obj.Name = value;
        end
    end

    methods (Static)
        %----------------------------------------
        function this = loadobj(SavedData)
            % Fetch variable with same name from variable manager
            % (ensures unique handle for each var name)
            if ischar(SavedData)
                varname = SavedData;
            else
                % Pre R14sp3 save format
                varname = SavedData.Name;
            end
            this = hds.variable;
            this.Name = varname;
        end
    end
end

