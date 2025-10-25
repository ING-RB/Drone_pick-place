classdef VEDataAttributes  < internal.matlab.datatoolsservices.DefaultDataAttributes
    % VEDATAATTRIBUTES Extends from DataAttributesInterace and provides
    % DataAttributes for VE supported variables.
    
    % Copyright 2019-2024 The MathWorks, Inc.

    properties
        isCellStr = false;
        isNumericObject = false;
        isUnsupported = false;
        isRowOrColumnVector = false;
        isArrayVector = false;
    end
    
    methods        
        function obj = VEDataAttributes(variableData, varSize)
            if (nargin < 2)
                varSize = size(variableData);
            end
            obj@internal.matlab.datatoolsservices.DefaultDataAttributes(variableData, varSize);
            
            if isstruct(variableData)
                varDims = length(varSize);
                if varDims == 2
                    if ~obj.isScalar && (varSize(1) == 1 || varSize(2) == 1)
                        % Show struct row or column vectors in array view
                        obj.('isRowOrColumnVector') = true;
                    end
                    
                    % g2346677: Empty MxN struct are unsupported and should
                    % have the isUnsupported data attribute
                    if isempty(variableData)
                        obj.('isUnsupported') = true;
                    end
                end
            end
            try
                % Exclude other datatpes from isobject check. Straighten this
                % out with the MLManager switchyard.
                
                % g2374723: Ensure data is not a primitive numeric when
                % checking for objects using ishandle to catch false positives
                % due to open figures.
                if (~istabular(variableData) && ~isstring(variableData) && ...
                        ~iscategorical(variableData) && ~iscell(variableData) && ...
                        ~isdatetime(variableData) && ~isduration(variableData) && ...
                        ~iscalendarduration(variableData) && ~ischar(variableData) && ...
                        ~isstruct(variableData) && ~isa(variableData, 'collection') && ~isa(variableData, 'dataset')) && ...
                        ((isobject(variableData) || (isnumeric(variableData) && ...
                            ~internal.matlab.datatoolsservices.VariableUtils.isPrimitiveNumeric(variableData))))

                    if isnumeric(variableData)
                        obj.('isNumericObject') = true;
                    elseif (isequal(varSize, [1, 1]) || numel(variableData) == 1)
                        obj = internal.matlab.variableeditor.VEDataAttributes.updateAttributesForObjectData(...
                            variableData, obj);
                    elseif isvector(variableData) && ~isa(variableData, 'optim.problemdef.OptimizationConstraint') && ...
                            (isobject(variableData) && ~isempty(properties(variableData)))
                        % Show struct row or column vectors in array view
                        % except for Optimization Objects because they
                        % report their properties differently
                        obj.('isRowOrColumnVector') = true;
                    end
                end
                
                % For chars that 2D but cannot be displayed, mark dataAttribute
                % as unsupported.
                if (ischar(variableData) && length(varSize) == 2 && ...
                        (varSize(1) > 1 || varSize(2) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH))
                    obj.('isUnsupported') = true;
                end
                
                if iscellstr(variableData) %#ok<ISCLSTR>
                    obj.('isCellStr') = true;
                end
                
                if isa(variableData, 'collection')
                    % Collection objects are always treated as MxN arrays, not
                    % scalar objects
                    obj.('isScalar') = false;
                end
                % If this is an optimization variable, set isScalar to true
                % to map to the right widget registry entry.
                if isa (variableData, 'InputOutputModel')
                      obj.('isScalar') = true;
                end

                % If this is a InputOutputModel, set isScalar to true
                % to map to the right widget registry entry.
                if isa (variableData, 'optim.problemdef.OptimizationVariable')
                      obj.('isScalar') = true;
                end
            catch
                % Ignore any errors, assume it is unsupported
                obj.('isUnsupported') = true;
            end
        end
        
        function dataAttributes = getDataAttributes(this, varargin)
            dataAttributes = this.getAttrAsStruct();
        end
    end
    
    methods(Static)
        % Static fn that updates 'attributes' for object like types.
        function attributes = updateAttributesForObjectData(objValue, attributes)
            % For UDD object types, display in
            % unsupportedViewModel
            if (isempty(meta.class.fromName(class(objValue))))
                attributes.('isUnsupported') = true;
            elseif (~isa(objValue, 'handle') || (~ismethod(objValue, 'isvalid') || isvalid(objValue))) ...
                    && ~isa(objValue, 'internal.matlab.variableeditor.NullValueObject')
                % Show scalar objects that have public
                % properties in the object view.  Invalid
                % objects, and objects with no public
                % properties, are shown in the unsupported
                % view.
                if ~isempty(properties(objValue))
                    attributes.isScalar = true;
                else
                    attributes.('isUnsupported') = true;
                end
            else
                attributes.('isUnsupported') = true;
            end                
        end
    end
end

