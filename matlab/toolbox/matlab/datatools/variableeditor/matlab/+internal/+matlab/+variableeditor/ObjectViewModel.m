classdef ObjectViewModel < internal.matlab.variableeditor.StructureViewModel

    %OBJECTVIEWMODEL
    % Abstract Object View Model.  Extends the StructureViewModel, because
    % the view for both objects and structures is very similar.

    % Copyright 2013-2025 The MathWorks, Inc.

    properties (Hidden = true, Transient)
        % metaclass data is used to determine read-only properties
        MetaclassData;

        % Deletion listener for the MetaclassData.  This will be deleted
        % when the class information for this object is reloaded
        DeletionListener = [];
    end

    methods (Access = public)
        % Constructor
        function this = ObjectViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.StructureViewModel(dataModel, viewID, userContext);

            % Initialize the metaclass information for later
            this.MetaclassData = dataModel.getMetaClassInfo;
            this.addDeletionListener();
        end

        % Destructor
        function delete(this)
            if ~isempty(this.DeletionListener)
                this.removeDeletionListener();
            end
        end
    end

    methods (Access = protected)
        function initFieldColumns(this, userContext)
            this.initFieldColumns@internal.matlab.variableeditor.StructureViewModel(userContext);
            fieldColumn = this.findFieldByHeaderName("Name");
            fieldColumn.setHeaderTagName(getString(message('MATLAB:codetools:variableeditor:Property')));
        end

        % Property name editing is not supported for object views.
        function isEditable = isColumnEditable(~, fieldColumn)
            if strcmp(fieldColumn.getHeaderName(), "Name")
                isEditable = false;
            else
                isEditable = fieldColumn.Editable;
            end
        end

        function isAllowed = setAccessAllowed(this, propertyName)
            % Returns true if the property has setAccess = public, and
            % false otherwise. If Dependent=true, returns false.
            isAllowed = [];
            if ~isempty(this.MetaclassData)
                propList = this.MetaclassData.PropertyList;
                prop = findobj(propList, 'Name', propertyName);
                if ~isempty(prop)
                    if this.DataModel.objectBeingDebugged()
                        isAllowed = any(cellfun(@(x) isequal(prop.SetAccess, x), {'public', 'protected', 'private'})) && ~prop.Dependent;
                    else
                        isAllowed = any(cellfun(@(x) isequal(prop.SetAccess, x), {'public'})) && ~prop.Dependent;
                    end
                end
            end

            if isempty(isAllowed)
                % assume false, but look for another way to find out if the
                % property is settable
                isAllowed = false;
                currObj = this.getData();

                if ismember('findprop', methods(currObj))
                    % If findprop is defined for the object, use it to try
                    % to get the property
                    p = findprop(currObj, propertyName);
                    if ~isempty(p)
                        isAllowed = isequal(p.SetAccess, 'public') && ~p.Dependent;
                    end
                else
                    % Check if the object has a set command which returns
                    % all of the settable properties.
                    try
                        propsList = set(currObj);
                        if ~isempty(propsList) && ...
                                any(ismember(fieldnames(propsList), propertyName))
                            isAllowed = true;
                        end
                    catch
                    end
                end
            end
        end
    end

    methods(Access = protected)
        function [] = addDeletionListener(this)
            % Adds a deletion listener to the metaclass data.  This will be
            % destroyed if the class definition changes
            if ~isempty(this.DeletionListener)
                this.removeDeletionListener();
            end

            this.DeletionListener = event.listener(this.MetaclassData, ...
                'ObjectBeingDestroyed', @this.deletionCallback);
        end

        function [] = removeDeletionListener(this)
            % Removes the deltion listener for the metaclass data
            delete(this.DeletionListener);
            this.DeletionListener = [];
        end

        function [] = deletionCallback(this, varargin)
            % if variable metadata has been deleted, this means that the
            % class definition has changed - a full redisplay is required
            this.MetaclassData = metaclass(this.DataModel.Data);
            this.addDeletionListener();
            %             this.refresh([], struct('Range', []));
        end

        function fields = getFields(this, data)
            % Protected method to get the fields from the data.
            % Because objects reuse much of the structure code, they
            % override this method to call properties instead of
            % fieldnames.
            if this.DataModel.objectBeingDebugged()
                fields = fieldnames(this.DataModel.ObjectStruct);
            else
                fields = properties(data);
            end
            % Ensure properties returned are a column vector for
            % column-wise value formatting.
            fields = fields(:);
        end

        function [cellData, virtualVals, accessVals] = getRenderedCellData(this, data, fieldNames)
            arguments
                this
                data % "data" is a struct or an object; it can be a struct if an object is
                     % being inspected mid-breakpoint.
                     % We cannot add a "mustBeA" constraint because some classes, such as
                     % "matlab.ui.Figure", aren't recognized as objects.
                fieldNames cell
            end

            % Override getRenderedCellData from StructureViewModel to handle virtual objects
            if this.DataModel.IsVirtual
                virtualVals = false(size(fieldNames));
                cellData = cell(length(fieldNames), 1);
                for idx = 1:length(fieldNames)
                    if this.DataModel.IsVirtual && isVariableEditorVirtualProp(data, fieldNames(idx))
                        virtualVals(idx) = true;
                        cellData{idx} = internal.matlab.datatoolsservices.FormatDataUtils.getVirtualObjPropValue(data, fieldNames(idx));
                    else
                        cellData{idx} = data.(fieldNames{idx});
                    end
                end
            else
                [cellData, virtualVals] = getRenderedCellData@internal.matlab.variableeditor.StructureViewModel(this, data, fieldNames);
            end

            % Determine the property access for the given field names.
            % accessVals will be something like: {'public'; 'protected'; 'private'}
            accessVals = cell(length(fieldNames), 1);
            m = this.DataModel.getMetaClassInfo();
            acc = {m.PropertyList.GetAccess};
            p = string({m.PropertyList.Name});

            for idx = 1:length(fieldNames)
                % check for exact match of property names in PropertyList
                if any(strcmp(p, fieldNames{idx}))
                    fieldAccess = acc(p == fieldNames{idx});

                    if ischar(fieldAccess{:})
                        accessVals(idx) = fieldAccess;
                    else
                        % g3558641: The Variable Editor does not have a way of representing multi-class
                        % property access. If this is the case, we default to treating this property
                        % as private.
                        accessVals{idx} = 'private';
                    end
                else
                    % This will happen with inherited properties of classes
                    % which are private -- they aren't included in the metadata
                    accessVals{idx} = 'private';
                end
            end
        end
    end
end