classdef ParameterizationFooterService < matlab.unittest.internal.services.testfooter.TestFooterService
    %

    % Copyright 2022 The MathWorks, Inc.

    methods (Access=protected)
        function footer = getFooter(~, suite, ~)
            import matlab.unittest.internal.diagnostics.PlainString;
            import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;

            parameterization = [suite.Parameterization];
            parameters = getUniqueParameters(parameterization);
            
            numParameters = height(parameters);
            if numParameters == 0
                label = getString(message("MATLAB:unittest:TestSuite:ZeroParameterizationsFooter"));
            elseif numParameters == 1
                label = getString(message("MATLAB:unittest:TestSuite:SingleParameterizationFooter"));
            else
                label = getString(message("MATLAB:unittest:TestSuite:MultipleParameterizationsFooter", numParameters));
            end

            % Early return if hyperlinking is not necessary
            if isempty(parameters)
                footer = PlainString(label);
                return;
            end

            commandToDisplayParameters = sprintf("matlab.unittest.internal.diagnostics.displayCellArrayAsTable([{%s}, {%s}], {'%s' '%s'})", ...
                sprintf("'%s';", parameters{:,1}), ...    % First column (Parameter Property)
                sprintf("'%s';", parameters{:,2}), ...    % Second column (Parameter Name)
                "Property", ...                           % First column name
                "Name");                                  % Second column name
            footer = CommandHyperlinkableString(label, commandToDisplayParameters);
        end
    end
end


function parameters = getUniqueParameters(parameterization)
% Determine unique parameters.

if isempty(parameterization)
    parameters = {};
    return;
end

% Use reserved characters that can't appear in the property or name.
PROPERTY_NAME_PAIR_DELIMITER  = '#';
PROPERTY_NAME_COMBO_SEPARATOR = '$';

parameters = [{parameterization.Property}' {parameterization.Name}'];

% Join cell array of parameters in this form:
% param1#loop1$param2#loop2
% # joins parameter property/name combination
% $ separates property/name combinations
delimiter = cell(1, numel(parameters)-1);
delimiter(1:2:end) = {PROPERTY_NAME_PAIR_DELIMITER};
delimiter(2:2:end) = {PROPERTY_NAME_COMBO_SEPARATOR};
joinedString = strjoin(parameters', delimiter);

% Split the string into parameter property/name combinations
parameters = strsplit(joinedString, PROPERTY_NAME_COMBO_SEPARATOR);

% Get unique parameters
parameters = unique(parameters);

% Split parameter combinations into property/name pairs (N x 2 cell array)
parameters = cellfun(@(s) strsplit(s, PROPERTY_NAME_PAIR_DELIMITER), parameters, UniformOutput=false);
parameters = reshape([parameters{:}], 2, numel(parameters))';
end

% LocalWords:  Hyperlinkable Parameterizations
