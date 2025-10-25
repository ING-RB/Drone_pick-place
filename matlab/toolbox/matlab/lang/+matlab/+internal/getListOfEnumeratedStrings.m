function enumeratedStrings = getListOfEnumeratedStrings(input)
% This function retrieves the list of possible values corresponding to a
% matlab.metadata.Property
%   Input - matlab.metadata.Property
%   Output - Cell array of possible values, if any
% 
% The property must be retrieved from a class that can be instantiated. 
% 
% The function returns the possible values for the following types of
% properties:
%
% a) Property whose type is an enumeration - Possible values returned as a
%    cell array of char vectors
% b) Property restricted to a set of char vectors by the mustBeMember
%    validation function - Possible values returned as a cell array of
%    char vectors
% c) Property restricted to a set of strings by the mustBeMember validation
%    function - Possible values returned as a cell array of strings
% d) Property restricted to a set of numbers by the mustBeMember validation
%    function - Possible values returned as a cell array of numeric values
% e) Property is defined using the old validation syntax and its datatype
%    overrides the getPossibleValues method to return a list of possible
%    values
%
% When the function returns an empty cell array, one of the following is
% true:
% a) The property is defined using the old property validation syntax 
% b) The property is not typed
% c) There is an error in the property definition

% Copyright 2019-2023 The MathWorks, Inc.

    enumeratedStrings = {};  
    
    % If input is not a matlab.metadata.Property, we must issue an error
    if ~isa(input, 'matlab.metadata.Property')
        error('MATLAB:class:RequireClass', 'Input must be a matlab.metadata.Property');
    else
        if ~isempty(input) && isvalid(input)
            % If the property is associated with a datatype that defines a
            % finite set of possible values, we retrieve the possible
            % values by querying its 'PossibleValues' property            
            if isa(input.Type, 'matlab.metadata.EnumeratedType')
                enumeratedStrings = input.Type.PossibleValues;
            else
                % If the property is not associated with a datatype that
                % defines a set of possible values, we do the following:
   
                % STEP 1: Get the matlab.metadata.Validation for the property - This
                %         shows up only if a property has been defined
                %         using the new property type validation syntax
                %
                % STEP 2: Once the matlab.metadata.Validation has been retrieved, it
                %         has 3 properties. We first check to see what the
                %         Class property points to. If it is a enumeration,
                %         we get the possible values from it.
                %         
                %         a) In addition, if validation functions are 
                %            defined, the enum values are evaluated for all
                %            of the validation functions. Invalid values 
                %            are removed from the list of possible values 
                %            and this filtered list is returned. 
                %         
                %         b) If no validation functions are defined, we 
                %            return the list of enum member names as a 
                %            cellstr
                %
                % STEP 3: If the property defines a class restriction, but
                %         that does not correspond to an enumeration, we 
                %         check if the property defines a set of validation
                %         functions. If it does, we get the possible values
                %         from the mustBeMember functions. Then, these 
                %         values are coerced to the specified class. Finally,
                %         these coerced values are evaluated for all of the
                %         validation functions defined, removing the 
                %         invalid ones. The filters list is returned
                %
                % STEP 4: If the property does not specify a class 
                %         restriction, we check if the property defines a
                %         set of validation functions. If it does, we get 
                %         the possible values from the mustBeMember functions.
                %         Then, these values are evaluated for all of the 
                %         validation functions, removing the invalid ones.
                %         The filtered list is returned                
                
                % STEP 1: Identifying properties defined using the new
                % property validation syntax
                validation = input.Validation;      
                                
                if ~isempty(validation)
                    % STEP 2: Identifying enum typed properties. If they
                    % exist, run it through all the validation functions
                    % and return the filtered list
                    cls = validation.Class;
                    
                    if ~isempty(cls) && cls.Enumeration
                        enumeratedStrings = getPossibleValuesFromEnum(validation);
                    elseif ~isempty(cls)&& ~isempty(validation.ValidatorFunctions)
                        % STEP 3: If there is a non-enum class restriction or the class
                        % restriction does not correspond to an enumeration, we
                        % try to extract the possible values from the
                        % mustBeMember validation function, if defined. These
                        % values are coerced to the specified class
                        % restriction, if one exists. Finally, the values are
                        % validated against all the validation functions and
                        % the filtered results are returned
                        enumeratedStrings = getListOfPossibleValuesFromMustBeMemberWithCoercion(validation);
                    elseif ~isempty(validation.ValidatorFunctions)
                        % STEP 4: If there is no class restriction , we try to
                        % extract the possible values from the mustBeMember
                        % validation function, if defined. These values are
                        % then validated against all the validation 
                        % functions and the filtered results are returned
                        enumeratedStrings = getListOfPossibleValuesFromMustBeMemberWithoutCoercion(validation);
                    end
                end                
            end
            
            % Making sure the output is always a cell column vector
             if ~isempty(enumeratedStrings) && ~iscolumn(enumeratedStrings)
                 enumeratedStrings = reshape(enumeratedStrings,numel(enumeratedStrings),1);
             end
        else
            % Input must not be an empty matlab.metadata.Property
            error('MATLAB:class:RequireScalar', 'Input must be scalar');
        end
    end
end

function out = validateSingleValueAgainstValidationFunctions(value, valfcns)
    % This helper function validates a single values against all the
    % validation functions defined for the property. If any one of them
    % errors, the value is considered invalid and we return an empty cell
    % array. 
    out = value;   
    
     for j=1:numel(valfcns)
        fcn = valfcns{j};
        
        try
            fcn(value);
        catch
            % The current value does not satisfy the validation
            % function vafcns{j}. So, we break from the for loop and
            % discard this value
            out = {};
            break;
        end        
     end
end

function enumeratedStrings = getPossibleValuesFromEnum(validation)
    % This helper functions returns the possible values obtained from the
    % enum class restriction. It fetches the enum values and runs it
    % through all the validation functions defined. The inavlid members are
    % removed and the filtered list is returned
    
    % Get the enum names and the enum values
    cls = validation.Class;
    [enumMembers, enumeratedStrings] = enumeration(cls.Name);
    
    if ~isempty(validation.ValidatorFunctions)
        enumeratedStrings = {};       
        
        for i=1:numel(enumMembers)
            result = validateSingleValueAgainstValidationFunctions(enumMembers(i), validation.ValidatorFunctions);
            
            % If the result is not empty, we convert the enum to a char and
            % append it
            if ~isempty(result)
                enumeratedStrings = [enumeratedStrings, enumMembers(i).char];
            end
        end        
        
    end
end

function enumeratedStrings = extractAndValidateListOfPossibleValuesFromMustBeMember(validation, performCoercion)
    % This helper function returns the list of possible values defined by
    % the mustBeMember validator. If the second input is set to true, these
    % values are then coerced to the specified class restricion. Finally, 
    % the values are evaluated for each of the specified validation
    % functions. In this process, the invalid values are removed and the 
    % filtered results are returned
    enumeratedStrings = {};   % The filteres list of possible values
    
    % For an instantiable class, the list of possible values have to be
    % homogenous. That is, it is either a numeric array or a cellstr array
    % or a string array. An invalid combination of these arrays is not
    % possible
    possibleValues = [];
    valfcns = validation.ValidatorFunctions;
    cls = validation.Class;
    
    % Get the possible values and coerce them
    for i=1:numel(valfcns)
        % Extract the second input to mustBeMember. For example, in the
        % following line:
        % {mustBeMember(prop, [1, 2, 3])}
        % We extract the second argument => [1, 2, 3]
        [a,~] = regexp(regexprep(func2str(valfcns{i}),'\(|\)',''), 'mustBeMember(.+?),','split'); 
        
        if (numel(a) > 1)
            % If the second input was extracted, evaluate the list of
            % possible values
            eval(['results = ' a{2} ';'])  
            
            if performCoercion
                % Coerce the values to the specified class restriction
                if isnumeric(results) || isstring(results)
                    uniformOutput = true;
                else
                    uniformOutput = false;
                end
                
                try
                    % Values can be coerced. So, it is added to the
                    % list of possible values
                    possibleValues = [possibleValues, arrayfun(@(x)builtin('_convert_to_class', cls.Name, x), results, 'UniformOutput', uniformOutput)];
                catch
                     % Value cannot be coerced. So, it is not added to the list                 
                end     
            else
                % No class coercion required. So, just append the values to
                % the list of possible values
                possibleValues = [possibleValues, results];
            end                  
        end
    end
    
    % Extract the unique values from the list of possible values
    % At this point the entries in the possibleValues should be of the same type as 
    % builtin method _convert_to_class should've been called if needed OR
    % the above execution of 'eval(['results = ' a{2} ';'])' will do some
    % automatic coercion
    if ~isempty(possibleValues)
        % If we are dealing with a cell array of strings, we need to convert to an array of 
        % strings so that the correct unique method will be called.  This would be the case if a 
        % property is defined as string type, but the mustBeMember was defined as a cellstr
        if (iscell(possibleValues) && isstring(possibleValues{1}))
            possibleValues = string(possibleValues);
        end
        
        if ~iscell(possibleValues) || (iscell(possibleValues) && ~iscell(possibleValues{1}))
            % We only get the unique values if we have a cellstr array. If we have a cell array of 
            % cell arrays, we do not do this; 
            possibleValues = unique(possibleValues, 'stable');
        end
    end
    
    % Convert possible values into a cell array
    if ~isempty(possibleValues) && ~iscell(possibleValues)
        if isnumeric(possibleValues)
            possibleValues = num2cell(possibleValues);
        elseif isstring(possibleValues)
            possibleValues = arrayfun(@(x){x},possibleValues);
        end
    end
    
    % Validate the possible values
    if ~isempty(possibleValues)
        for i=1:numel(possibleValues)
            valValue = validateSingleValueAgainstValidationFunctions(possibleValues{i}, valfcns);
            
            % If the result is not empty, we add it to the filtered list of
            % possible values
            if ~isempty(valValue)
                enumeratedStrings = [enumeratedStrings, possibleValues(i)];
            end
        end
    end
end

function enumeratedStrings = getListOfPossibleValuesFromMustBeMemberWithoutCoercion(validation)
    % This helper function returns the list of possible values defined by
    % the mustBeMember validator. These values are then evaludated for each
    % of the specified validation functions. In this process, the invalid
    % values are removed and the filtered results are removed
    enumeratedStrings = extractAndValidateListOfPossibleValuesFromMustBeMember(validation, false);
end

function enumeratedStrings = getListOfPossibleValuesFromMustBeMemberWithCoercion(validation)
    % This helper function returns the list of possible values defined by
    % the mustBeMember validator. The values are coerced to the specified 
    % class restriction. Then, these are evaluated for each of the
    % specified validation functions. In this process, the invalid values are 
    % removed and the filtered results are returned
    enumeratedStrings = extractAndValidateListOfPossibleValuesFromMustBeMember(validation, true);
end