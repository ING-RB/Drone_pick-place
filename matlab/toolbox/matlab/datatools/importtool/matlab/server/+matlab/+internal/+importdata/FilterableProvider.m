% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for filtering variables

% Copyright 2021 The MathWorks, Inc.

classdef FilterableProvider < handle

    properties
        % The filter function to apply to variables when determining the list to
        % short for import.  The function must error when the criteria isn't
        % met, or it can return a logical value.  It can be something like
        % @mustBeNumeric, @mustBeA, @isnumeric, @isempty, or any user defined
        % function with similar behavior.  FilterFunction can also be a cell
        % array of functions to apply as filters.
        FilterFunction = function_handle.empty;
    end

    methods(Hidden)
        function addVar = isValidForFilter(this, var, filterFuncs)
            % Call each of the filter function in filterFuncs for the variable
            % var. 
            addVar = true;

            % If it is set, apply the filter function.
            if ~isempty(this.FilterFunction)

                % Traverse the list of filter functions.  The variable
                % needs to pass all criteria to be added.
                for funcIdx = 1:length(filterFuncs)
                    func = filterFuncs{funcIdx};

                    if nargout(func) == 1
                        % The FilterFunction must return a logical, like
                        % isnumeric
                        addVar = func(var);
                    else
                        % The function, like @mustBeNumeric or @mustBe
                        % will error if the variable doesn't meet the
                        % criteria
                        func(var);
                    end

                    if ~addVar
                        break;
                    end
                end
            end
        end
    end
end