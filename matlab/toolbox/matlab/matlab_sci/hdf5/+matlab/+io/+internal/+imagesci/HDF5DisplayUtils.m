% This class is unsupported and might change or be removed without notice in a
% future version.

% Copyright 2010-2023 The MathWorks, Inc.

classdef HDF5DisplayUtils
    %HDF5DISPLAYUTILS Collection of utils for displaying HDF5 info
    %   This class contains static methods that help with generating
    %   display text for different aspects of HDF5 files. It is used by
    %   h5disp and HDF5 live task.

    methods (Static)

        %--------------------------------------------------------------------------
        function dispTxt = displayHDF5(options)

            % 'context' has two fields.
            %    mode - either 'min' or 'simple'
            %    source - this tells a function who called it. Values include
            %        'group', 'dataset', 'datatype', 'derived'.
            %        Behavior may change because of this.
            %
            % This function displays something like the following:
            %
            % HDF5 example.h5

            dispTxt = "";

            context.mode = options.Mode;

            if options.UseUtf8
                hinfo = h5info(options.Filename,options.Location, 'TextEncoding', 'UTF-8');
            else
                hinfo = h5info(options.Filename,options.Location);
            end

            fileTypeDescription = getString(message('MATLAB:imagesci:h5disp:fileType'));
            % Is it a group?
            if isfield(hinfo,'Groups')
                fid = matlab.io.internal.imagesci.HDF5DisplayUtils.openHelper(hinfo.Filename);
                c = onCleanup( @() H5F.close(fid) );
                %%% parse this out
                [~,name,ext] = fileparts(hinfo.Filename);
                dispTxt = dispTxt + ...
                    sprintf('%s %s \n', fileTypeDescription,[name ext]) + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayGroup(hinfo,context,0,fid);

            elseif isfield(hinfo,'Class')
                % A named datatype can only exist as a member of a group.
                [~,name,ext] = fileparts(hinfo.Filename);
                context.source = 'group';
                dispTxt = dispTxt + ...
                    sprintf('%s %s \n', fileTypeDescription,[name ext]) + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatype(hinfo,context,0);
            else
                % Dataset
                [~,name,ext] = fileparts(hinfo.Filename);
                context.source = 'dataset';
                dispTxt = dispTxt + ...
                    sprintf('%s %s \n', fileTypeDescription,[name ext]) + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayDataset(hinfo,context,0);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayGroup(group,context,level,locID)
            %
            % This function would display something like the following:
            %
            % Group '/g4'
            %     Dataset 'lat'
            %         Size:  19
            %         MaxSize:  19
            %         Datatype:   H5T_IEEE_F64LE (double)
            %         ChunkSize:  []
            %         Filters:  none
            %         FillValue:  0.000000
            %     Dataset 'lon'
            %         Size:  36
            %         MaxSize:  36
            %         Datatype:   H5T_IEEE_F64LE (double)
            %         ChunkSize:  []
            %         Filters:  none
            %         FillValue:  0.000000
            %     Attributes:

            dispTxt = "";
            context.source = 'group';

            groupTypeLabel = getString(message('MATLAB:imagesci:h5disp:group'));
            dispTxt = dispTxt + sprintf ('%s%s ''%s'' \n', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), groupTypeLabel, group.Name);

            if ~strcmp(context.mode,'min')
                dispTxt = dispTxt + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttributes(group.Attributes,context,level+1);
            end

            gid = H5G.open(locID,group.Name);
            c = onCleanup( @() H5G.close(gid) );

            dispTxt = dispTxt + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayLinks(group.Links,context,level+1,gid) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayNamedDatatypes(group.Datatypes,context,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatasets(group.Datasets,context,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayChildGroups(group.Groups,context,level+1,gid);
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayChildGroups(groups,context,level,locID)
            % This function returns display text for all nested/child groups including
            % their attributes, links, named datatypes, datasets, and nested groups
            % within.

            dispTxt = "";
            for j = 1:numel(groups)
                dispTxt = dispTxt + ....
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayGroup(groups(j),context,level,locID);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayLinks(links,context,level,locID)
            % This function returns display text for all links including their type and
            % target

            dispTxt = "";
            for j = 1:numel(links)
                dispTxt = dispTxt + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayLink(links(j),context,level,locID);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayAttributes(attributes,context,level)
            %
            % This function displays something like

            % Attributes:
            %     'units':  'degrees_east'
            %     'CLASS':  'DIMENSION_SCALE'
            %     'NAME':  'lon'

            dispTxt = "";

            attrTypeLabel = getString(message('MATLAB:imagesci:h5disp:attribute'));
            if numel(attributes) > 0
                dispTxt = dispTxt + sprintf('%s%s:\n', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), attrTypeLabel);
                for j = 1:numel(attributes)
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttribute(attributes(j),context,level+1);
                end
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayNamedDatatypes(namedDatatypes,context,level)

            dispTxt = "";
            for j = 1:numel(namedDatatypes)
                dispTxt = dispTxt + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatype(namedDatatypes(j),context,level);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatasets(datasets,context,level)

            dispTxt = "";
            for j = 1:numel(datasets)
                dispTxt = dispTxt + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayDataset(datasets(j),context,level);
            end
        end


        %--------------------------------------------------------------------------
        function dispTxt = displayLink(link,context,level,locID)
            % Return display text for a link, including its name and
            % information about it
            %
            % This function displays something like:
            %
            % Dataset 'dset3'
            %     Type:      'hard link'
            %     Target:    '/dset1'

            dispTxt = "";

            linkLabel = getString(message('MATLAB:imagesci:h5disp:link'));
            if strcmp(context.mode,'min')
                dispTxt = dispTxt + ...
                    sprintf('%s%s ''%s''\n', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), linkLabel, link.Name);
                % We're done, the link name is sufficient.
                return;
            end

            switch(link.Type)
                case 'soft link'
                    % Soft links are symbolic links within an HDF5 file. Symbolic links
                    % are objects that assign a name in a group to a path. Symbolic
                    % links are not reference counted, and the target object may not
                    % exist.
                    dispTxt = dispTxt + ....
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), linkLabel, link.Name) + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayLinkMetadata(link, level+1);

                case 'external link'
                    % External links are symbolic links to objects located in external
                    % files. Symbolic links are objects that assign a name in a group
                    % to a path. Symbolic links are not reference-counted, and the
                    % target object may not exist.
                    dispTxt = dispTxt + ...
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), linkLabel, link.Name) + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayLinkMetadata(link, level+1);

                case 'hard link'
                    % Hard links are reference-counted and are always valid. When an
                    % object is created, a hard link is automatically created. An
                    % object can be deleted from the file by removing all the hard
                    % links to it.

                    objID = H5O.open(locID, link.Name, 'H5P_DEFAULT');
                    c = onCleanup( @() H5O.close(objID) );
                    info = H5O.get_info(objID);

                    % info.type is an enum defined as follows
                    % H5O_TYPE_UNKNOWN = -1,      Unknown object type
                    % H5O_TYPE_GROUP,             Object is a group
                    % H5O_TYPE_DATASET,           Object is a dataset
                    % H5O_TYPE_NAMED_DATATYPE,    Object is a committed (named) datatype
                    % H5O_TYPE_NTYPES             Number of different object types
                    switch info.type
                        case 0      % Object is a group
                            objLabel = getString(message('MATLAB:imagesci:h5disp:group'));
                        case 1      % Object is a dataset
                            objLabel = getString(message('MATLAB:imagesci:h5disp:dataset'));
                        case 2      % Object is a committed (named) datatype
                            objLabel = getString(message('MATLAB:imagesci:h5disp:datatype'));
                        otherwise   % Label it as simply an object
                            objLabel = getString(message('MATLAB:imagesci:h5disp:object'));
                    end
                    dispTxt = dispTxt + ...
                        sprintf('%s%s ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), objLabel, link.Name) + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayLinkMetadata(link, level+1);

                case 'user-defined link'
                    % Do nothing.
            end
        end

        function dispTxt = displayLinkMetadata(link, level)
            % Return display text containing link's information, like
            % Type and Target. Does not include link's name.

            dispTxt = "";

            typeLabel = getString(message('MATLAB:imagesci:h5disp:type'));

            switch(link.Type)
                case {'soft link', 'hard link'}
                    % show type and target
                    targetLabel = getString(message('MATLAB:imagesci:h5disp:target'));

                    dispTxt = dispTxt + ...
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                        typeLabel, link.Type) + ...
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                        targetLabel, link.Value{1});

                case 'external link'
                    % show type, target file, and target object
                    targetFileLabel = getString(message('MATLAB:imagesci:h5disp:targetFile'));
                    targetObjectLabel = getString(message('MATLAB:imagesci:h5disp:targetObject'));

                    dispTxt = dispTxt + ...
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                        typeLabel, link.Type) + ...
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                        targetFileLabel, link.Value{1}) + ...
                        sprintf('%s%s:  ''%s''\n', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                        targetObjectLabel, link.Value{2});

            end
        end


        %--------------------------------------------------------------------------
        function dispTxt = displayAttribute(attribute,~,level)
            % This helper function returns display text for an individual attribute,
            % including the name of the attribute and its value or its datatype and
            % size.

            dispTxt = sprintf('%s''%s'':  ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level),...
                attribute.Name) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttributeValue(attribute);
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayAttributeValue(attribute)
            % This helper function returns display text for an individual attribute,
            % excluding the name of the attribute. Most commonly it is the attribute
            % value or the attribute's datatype and size.

            dispTxt = "";
            switch(attribute.Dataspace.Type)
                case 'null'
                    switch(attribute.Datatype.Class)
                        case 'H5T_STRING'
                            dispTxt = dispTxt + sprintf('''''\n');
                        otherwise
                            % use [] for null
                            dispTxt = dispTxt + sprintf('[]\n');
                    end
                case 'scalar'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayScalarAttributeValue(attribute);

                case 'simple'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displaySimpleAttributeValue(attribute);
            end

        end


        %--------------------------------------------------------------------------
        function dispTxt = displayScalarAttributeValue(attribute)

            dispTxt = "";

            switch(attribute.Datatype.Class)

                case {'H5T_BITFIELD', 'H5T_INTEGER'}
                    dispTxt = dispTxt + sprintf('%d\n', attribute.Value);

                case 'H5T_ENUM'
                    dispTxt = dispTxt + sprintf('%s\n', attribute.Value{1});

                case 'H5T_FLOAT'
                    dispTxt = dispTxt + sprintf('%f\n', attribute.Value);

                case 'H5T_OPAQUE'

                    % Just a 'single' opaque element means a vector of data,
                    % which we can print.
                    for j = 1:numel(attribute.Value{1})
                        dispTxt = dispTxt + sprintf('%d ', attribute.Value(j));
                    end
                    dispTxt = dispTxt + newline;

                case 'H5T_STRING'
                    switch(class(attribute.Value))
                        case 'char'
                            dispTxt = dispTxt + sprintf('''%s''\n', attribute.Value);
                        case 'cell'
                            % Variable length string.  OK to print each value.
                            dispTxt = dispTxt + sprintf('''%s''', attribute.Value{1});
                            for j = 2:numel(attribute.Value)
                                dispTxt = dispTxt + sprintf(', ''%s''', attribute.Value{j});
                            end
                            dispTxt = dispTxt + newline;
                    end

                otherwise
                    % Compound, reference, array, vlen
                    if isempty(attribute.Datatype.Name)
                        dispTxt = dispTxt + sprintf('''%s''\n', attribute.Datatype.Class);
                    else
                        desc = getString(message('MATLAB:imagesci:h5disp:userDefinedDatatype'));
                        dispTxt = dispTxt + sprintf('%s ''%s''\n', desc, attribute.Datatype.Name);
                    end
            end

        end

        %--------------------------------------------------------------------------
        function dispTxt = displaySimpleAttributeValue(attribute)

            dispTxt = "";

            % The attribute dataspace has at least one extent, possibly more.
            switch(attribute.Datatype.Class)
                case {'H5T_BITFIELD', 'H5T_INTEGER'}
                    if isvector(attribute.Value)
                        for j = 1:numel(attribute.Value)
                            dispTxt = dispTxt + sprintf('%d ', attribute.Value(j));
                        end
                        dispTxt = dispTxt + newline;
                    else
                        dispTxt = dispTxt + ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.displayNDimensionalAttribute(attribute);
                    end

                case 'H5T_ENUM'
                    if isvector(attribute.Value)
                        dispTxt = dispTxt + sprintf('''%s''', attribute.Value{1});
                        for j = 2:numel(attribute.Value)
                            dispTxt = dispTxt + sprintf(', ''%s''', attribute.Value{j});
                        end
                        dispTxt = dispTxt + newline;
                    else
                        dispTxt = dispTxt + ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.displayNDimensionalAttribute(attribute);
                    end


                case 'H5T_FLOAT'
                    if isvector(attribute.Value)
                        for j = 1:numel(attribute.Value)
                            dispTxt = dispTxt + sprintf('%f ', attribute.Value(j));
                        end
                        dispTxt = dispTxt + newline;
                    else
                        dispTxt = dispTxt + ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.displayNDimensionalAttribute(attribute);
                    end


                case 'H5T_OPAQUE'
                    if numel(attribute.Value) == 1
                        for j = 1:numel(attribute.Value{1})
                            dispTxt = dispTxt + sprintf('%d ', attribute.Value(j));
                        end
                        dispTxt = dispTxt + newline;
                    elseif isvector(size(attribute.Value))
                        % This means that the opaque attribute is mx1 or 1xm
                        dispTxt = dispTxt + ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.displayNDimensionalAttribute(attribute,size(attribute.Value));
                    else
                        dispTxt = dispTxt + ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.displayNDimensionalAttribute(attribute);
                    end

                case 'H5T_STRING'
                    if (numel(attribute.Value) == 1) || isvector(attribute.Value)
                        % We can print single value strings or string vectors.
                        dispTxt = dispTxt + sprintf('''%s''', attribute.Value{1});
                        for j = 2:numel(attribute.Value)
                            dispTxt = dispTxt + sprintf(', ''%s''', attribute.Value{j});
                        end
                        dispTxt = dispTxt + newline;
                    else
                        dispTxt = dispTxt + ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.displayNDimensionalAttribute(attribute);
                    end

                otherwise
                    % arrays, vlens, compounds, references
                    if isempty(attribute.Datatype.Name)
                        dispTxt = dispTxt + sprintf('%s\n', attribute.Datatype.Class);
                    else
                        dispTxt = dispTxt + sprintf('%s\n', attribute.Datatype.Name);
                    end
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayNDimensionalAttribute(attribute,sz)
            % HDF5 allows for multi-dimensional attributes.  Rather than try to print
            % these out in their entirety, we just print their matlab size and hdf5
            % class.

            dispTxt = "";

            if nargin == 1
                sz = size(attribute.Value);
            end

            dispTxt = dispTxt + sprintf('%d', size(attribute.Value,1));
            for j = 2:ndims(attribute.Value)
                dispTxt = dispTxt + sprintf('x%d', sz(j));
            end

            dispTxt = dispTxt + sprintf(' %s\n', attribute.Datatype.Class);
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayBitfieldDatatype(datatype,~,~)

            dispTxt = "";

            desc = getString(message('MATLAB:imagesci:h5disp:uint',datatype.Size*8));
            switch(datatype.Size)
                case {1, 2, 4, 8}
                    dispTxt = dispTxt + sprintf('%s (%s)\n', datatype.Type, desc);
                otherwise
                    desc = getString(message('MATLAB:imagesci:h5disp:oddSizeBitfield',datatype.Size));
                    dispTxt = dispTxt + sprintf('%s (%s)\n', datatype.Type, desc);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatype(datatype,context,level)

            dispTxt = "";

            datatypeLabel = getString(message('MATLAB:imagesci:h5disp:datatype'));
            if isempty(datatype.Name)
                dispTxt = dispTxt + sprintf('%s%s:   ', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                    datatypeLabel);
            else
                switch(context.source)
                    case 'group'
                        % We have a named datatype object, so we should describe it in
                        % full.  But first, remove the leading path from the name of
                        % the datatype.
                        sep = strfind(datatype.Name,'/');
                        dispTxt = dispTxt + sprintf('%s%s ''%s''', ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                            datatypeLabel, datatype.Name(sep(end)+1:end));

                        if strcmp(context.mode,'min')
                            % In minimal mode, we just display the name of the object.
                            dispTxt = dispTxt + newline;
                            return;
                        end

                        % Not in minimal mode.  Prepare for the rest of the datatype
                        % description.
                        dispTxt = dispTxt + sprintf(':  ');

                    case 'dataset'
                        % The named datatype is described elsewhere in full, so just
                        % refer to it by name. and we are done.
                        dispTxt = dispTxt + sprintf('%s%s:  ''%s''\n', ...
                            matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level),... 
                            datatypeLabel, datatype.Name);
                        return
                end
            end

            context.source = 'datatype';

            dispTxt = dispTxt + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeByClass(datatype,context,level);

            if numel(datatype.Attributes) > 0
                % Named datatype with attributes.
                dispTxt = dispTxt + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttributes(datatype.Attributes,context,level+1);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeByClass(datatype,context,level)

            switch(datatype.Class)
                case 'H5T_ARRAY'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayArrayDatatype(datatype,context,level+1);

                case 'H5T_BITFIELD'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayBitfieldDatatype(datatype,context,level+1);

                case 'H5T_COMPOUND'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeCompound(datatype,context,level+1);

                case 'H5T_ENUM'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeEnum(datatype,context,level+1);

                case 'H5T_FLOAT'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayFloatingPointDatatype(datatype);

                case 'H5T_INTEGER'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayIntegerDatatype(datatype);

                case 'H5T_OPAQUE'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeOpaque(datatype,context,level+1);

                case 'H5T_REFERENCE'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeReference(datatype,context,level+1);

                case 'H5T_STRING'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeString(datatype,context,level+1);

                case 'H5T_TIME'
                    dispTxt = sprintf('H5T_TIME (unsupported)\n');

                case 'H5T_VLEN'
                    dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeVLEN(datatype,context,level+1);

                otherwise
                    error(message('MATLAB:imagesci:h5disp:unhandledClass', datatype.Class));
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayIntegerDatatype(datatype)
            %
            % This function displays something like the following:
            %
            %         Datatype:   H5T_STD_I32BE (int32)

            dispTxt = "";

            switch(datatype.Type)
                case { 'H5T_STD_U64LE', 'H5T_STD_U64BE', ...
                        'H5T_STD_U32LE', 'H5T_STD_U32BE', ...
                        'H5T_STD_U16LE', 'H5T_STD_U16BE', ...
                        'H5T_STD_U8LE', 'H5T_STD_U8BE' }
                    uintDesc = getString(message('MATLAB:imagesci:h5disp:uint',datatype.Size*8));
                    dispTxt = dispTxt + sprintf('%s (%s)\n', datatype.Type, uintDesc);

                case { 'H5T_STD_I64LE', 'H5T_STD_I64BE', ...
                        'H5T_STD_I32LE', 'H5T_STD_I32BE', ...
                        'H5T_STD_I16LE', 'H5T_STD_I16BE', ...
                        'H5T_STD_I8LE', 'H5T_STD_I8BE' }
                    intDesc = getString(message('MATLAB:imagesci:h5disp:int',datatype.Size*8));
                    dispTxt = dispTxt + sprintf('%s (%s)\n', datatype.Type, intDesc);

                otherwise
                    dispTxt = dispTxt + sprintf('%s\n', datatype.Type);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayFloatingPointDatatype(datatype)
            %
            % This function displays something like the following:
            %
            %     Datatype:   H5T_IEEE_F64LE (double)

            dispTxt = "";

            switch(datatype.Type)
                case { 'H5T_IEEE_F32BE', 'H5T_IEEE_F32LE' }
                    desc = getString(message('MATLAB:imagesci:h5disp:single'));
                    dispTxt = dispTxt + sprintf('%s (%s)\n', datatype.Type, desc);

                case { 'H5T_IEEE_F64BE', 'H5T_IEEE_F64LE' }
                    desc = getString(message('MATLAB:imagesci:h5disp:double'));
                    dispTxt = dispTxt + sprintf('%s (%s)\n', datatype.Type, desc);

                otherwise
                    dispTxt = dispTxt + sprintf('%s\n', datatype.Type);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeVLEN(hinfo,context,level)
            %
            % This function displays something like the following:
            %
            %         Datatype:   H5T_VLEN
            %            Base Type: H5T_IEEE_F32LE (single)

            dispTxt = "";

            switch(context.source)
                case {'dataset', 'datatype', 'derived'}
                    % We are in the middle of a line, no need to indent.

                otherwise
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level-1);
            end

            dispTxt = dispTxt + sprintf('%s\n', hinfo.Class);

            desc = getString(message('MATLAB:imagesci:h5disp:baseType'));
            dispTxt = dispTxt + sprintf('%s%s: ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), desc);

            context.source = 'derived';

            dispTxt = dispTxt + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeByClass(hinfo.Type,context,level);

        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeOpaque(hinfo,~,level)
            %
            % This function displays something like the following:
            %
            %     Datatype:   H5T_OPAQUE
            %         Length: 1
            %         Tag:  1-byte opaque type

            dispTxt = "";

            dispTxt = dispTxt + sprintf('%s\n', hinfo.Class);

            desc = getString(message('MATLAB:imagesci:h5disp:length'));
            dispTxt = dispTxt + sprintf('%s%s: %d\n', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), desc, hinfo.Type.Length);

            desc = getString(message('MATLAB:imagesci:h5disp:tag'));
            dispTxt = dispTxt + sprintf('%s%s:  %s\n', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), desc, hinfo.Type.Tag);

        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeEnum(hinfo,~,level)
            %
            % This function displays something like the following:
            %
            %     Datatype:   H5T_ENUM
            %         Base Type:  H5T_STD_I32LE
            %         Member 'RED':  0
            %         Member 'GREEN':  1

            dispTxt = "";

            dispTxt = dispTxt + sprintf('%s\n', hinfo.Class);

            desc = getString(message('MATLAB:imagesci:h5disp:baseType'));
            dispTxt = dispTxt + sprintf('%s%s:  %s\n', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                desc, hinfo.Type.Type);

            desc = getString(message('MATLAB:imagesci:h5disp:member'));
            for j = 1:numel(hinfo.Type.Member)
                dispTxt = dispTxt + sprintf('%s%s ''%s'':  %d\n', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                    desc, hinfo.Type.Member(j).Name, ...
                    hinfo.Type.Member(j).Value);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeCompound(hinfo,context,level)
            %
            % This function displays something like the following:
            %
            %     Datatype:   H5T_COMPOUND
            %         Member 'a':  H5T_STD_I8LE (int8)
            %         Member 'b':  H5T_IEEE_F64LE (double)

            dispTxt = "";

            switch(context.source)
                case {'dataset', 'datatype', 'derived'}
                    % We are in the middle of a line, no need to indent.

                otherwise
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level-1);
            end

            desc = getString(message('MATLAB:imagesci:h5disp:h5tcompound'));
            dispTxt = dispTxt + sprintf('%s\n', desc)+ ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeCompoundMembers(hinfo.Type.Member,context,level);
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeCompoundMembers(member,context,level)

            dispTxt = "";
            context.source = 'derived';
            memberDesc = getString(message('MATLAB:imagesci:h5disp:member'));

            for j = 1:numel(member)
                dispTxt = dispTxt + sprintf('%s%s ''%s'':  ', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                    memberDesc, member(j).Name) + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeByClass(member(j).Datatype,context,level);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeReference(hinfo,~,~)
            %
            % This function displays something like the following:
            %
            %     Datatype:   H5T_REFERENCE

            dispTxt = sprintf("%s\n", hinfo.Class);
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayArrayDatatype(hinfo,context,level)
            % This function displays something like the following:
            %
            %     Datatype:   H5T_ARRAY
            %         Size: 3
            %         Base Type:  H5T_STD_I32LE (int32)

            dispTxt = "";

            switch(context.source)
                case {'dataset', 'datatype', 'derived'}
                    % We are in the middle of a line, no need to indent.

                otherwise
                    dispTxt = dispTxt + sprintf('%s', ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level-1));
            end

            desc = getString(message('MATLAB:imagesci:h5disp:h5tarray'));
            dispTxt = dispTxt + sprintf('%s\n',desc);

            desc = getString(message('MATLAB:imagesci:h5disp:size'));
            dispTxt = dispTxt + sprintf('%s%s: ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), desc);
            dispTxt = dispTxt + sprintf('%d', hinfo.Type.Dims(1));
            for j = 2:numel(hinfo.Type.Dims)
                dispTxt = dispTxt + sprintf('x%d',hinfo.Type.Dims(j));
            end
            dispTxt = dispTxt + newline;

            label = getString(message('MATLAB:imagesci:h5disp:baseType'));
            dispTxt = dispTxt + sprintf('%s%s:  ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), label);
            switch(hinfo.Type.Datatype.Class)
                case 'H5T_ARRAY'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayArrayDatatype(...
                        hinfo.Type.Datatype,context,level+1);
                case 'H5T_BITFIELD'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayBitfieldDatatype(...
                        hinfo.Type.Datatype,context,level+1);
                case 'H5T_COMPOUND'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeCompound(...
                        hinfo.Type.Datatype,context,level+1);
                case 'H5T_ENUM'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeEnum(...
                        hinfo.Type.Datatype,context,level+1);
                case 'H5T_INTEGER'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayIntegerDatatype(...
                        hinfo.Type.Datatype);
                case 'H5T_FLOAT'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayFloatingPointDatatype(...
                        hinfo.Type.Datatype);
                case 'H5T_REFERENCE'
                    dispTxt = dispTxt + ...
                        displayReferenceDatatype(hinfo.Type.Datatype,context,level+1);
                case 'H5T_OPAQUE'
                    dispTxt = dispTxt + ...
                        displayOpaqueDatatype(hinfo.Type.Datatype,context,level+1);
                case 'H5T_STRING'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeString(...
                        hinfo.Type.Datatype,context,level+1);
                case 'H5T_VLEN'
                    dispTxt = dispTxt + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeVLEN(...
                        hinfo.Type.Datatype,context,level+1);
                otherwise
                    error(message('MATLAB:imagesci:h5disp:unhandledClass', ...
                        hinfo.Type.Class));
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDatatypeString(hinfo,~,level)
            % This function will display something like the example below:
            %
            %     Datatype:   H5T_STRING
            %         String Length: 3
            %         Padding: H5T_STR_NULLTERM
            %         Character Set: H5T_CSET_ASCII
            %         Character Type: H5T_C_S1

            dispTxt = "";
            dispTxt = dispTxt + sprintf('%s\n', hinfo.Class);

            % Variable length strings should be clearly designated.
            if ischar(hinfo.Type.Length) && strcmp(hinfo.Type.Length,'H5T_VARIABLE')
                label = getString(message('MATLAB:imagesci:h5disp:stringLength', ...
                    'variable'));
            else
                label = getString(message('MATLAB:imagesci:h5disp:stringLength', ...
                    num2str(hinfo.Type.Length)));
            end
            dispTxt = dispTxt + ...
                sprintf('%s%s\n', matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                label);

            label = getString(message('MATLAB:imagesci:h5disp:padding'));
            dispTxt = dispTxt + ...
                sprintf('%s%s: %s\n', matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                label, hinfo.Type.Padding);

            label = getString(message('MATLAB:imagesci:h5disp:characterSet'));
            dispTxt = dispTxt + sprintf('%s%s: %s\n', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                label, hinfo.Type.CharacterSet);

            label = getString(message('MATLAB:imagesci:h5disp:characterType'));
            dispTxt = dispTxt + sprintf('%s%s: %s\n', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                label, hinfo.Type.CharacterType);

        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDataset(dataset,context,level)
            % This function will display something like the example that follows below.
            %
            % Dataset 'lon'
            %     Size:  36
            %     MaxSize:  36
            %     Datatype:   H5T_IEEE_F64LE (double)
            %     ChunkSize:  []
            %     Filters:  none
            %     FillValue:  0.000000
            %     Attributes:
            %         'units':  'degrees_east'
            %         'CLASS':  'DIMENSION_SCALE'
            %         'NAME':  'lon'

            dispTxt = "";

            context.source = 'dataset';

            label = getString(message('MATLAB:imagesci:h5disp:dataset'));
            dispTxt = dispTxt + sprintf('%s%s ''%s'' ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                label, dataset.Name);

            if strcmp(context.mode,'min')
                % We're done, the dataset name is sufficient.
                dispTxt = dispTxt + newline;
                return
            end

            dispTxt = dispTxt + newline + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDataspace(dataset.Dataspace,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatype(dataset.Datatype,context,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayChunking(dataset.ChunkSize,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayFilters(dataset.Filters,context,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayFillValue(dataset,context,level+1) + ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttributes(dataset.Attributes,context,level+1);
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayFillValue(dinfo,~,level)
            % Don't display anything if a fill value does not exist.  If it does exist
            % and is numeric, display in full.  If it exists and is non-numeric, just
            % indicate its presence.

            dispTxt = "";

            if isempty(dinfo.FillValue)
                return
            end

            desc = getString(message('MATLAB:imagesci:h5disp:fillValue'));
            dispTxt = dispTxt + sprintf('%s%s:  ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), desc);
            switch dinfo.Datatype.Class
                case {'H5T_ARRAY', 'H5T_COMPOUND', 'H5T_REFERENCE', 'H5T_VLEN'}
                    dispTxt = dispTxt + sprintf('%s\n', dinfo.Datatype.Class);

                case 'H5T_ENUM'
                    dispTxt = dispTxt + sprintf('''%s''\n', dinfo.FillValue);

                case 'H5T_FLOAT'
                    dispTxt = dispTxt + sprintf('%f\n', dinfo.FillValue);

                case {'H5T_OPAQUE', 'H5T_BITFIELD', 'H5T_INTEGER'}
                    dispTxt = dispTxt + sprintf('%d', dinfo.FillValue(1));
                    for j = 2:numel(dinfo.FillValue)
                        dispTxt = dispTxt + sprintf(' %d', dinfo.FillValue(j));
                    end
                    dispTxt = dispTxt + newline;

                case 'H5T_STRING'
                    if iscell(dinfo.FillValue)
                        % It's a variable length string
                        if numel(dinfo.FillValue) == 1
                            dispTxt = dispTxt + sprintf('''%s''\n', dinfo.FillValue{1});
                        else
                            dispTxt = dispTxt + sprintf('%s\n', dinfo.Datatype.Class);
                        end
                    else
                        dispTxt = dispTxt + sprintf('''%s''\n', dinfo.FillValue);
                    end

                otherwise
                    error(message('MATLAB:imagesci:h5disp:unhandledClass', ...
                        dinfo.Datatype.Class));
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayFilters(filters,~,level)
            % This helper function returns display text for all given filters (using
            % displayFilter function on each of them)

            % This function will display something like the example that follows below.
            %
            %         Filters:  deflate(6)

            dispTxt = "";

            desc = getString(message('MATLAB:imagesci:h5disp:filters'));
            dispTxt = dispTxt + sprintf('%s%s:  ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), desc);
            if isempty(filters)
                dispTxt = dispTxt + sprintf('none');
            else
                dispTxt = dispTxt + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displayFilter(filters(1));
                for j = 2:numel(filters)
                    dispTxt = dispTxt + ", " + ...
                        matlab.io.internal.imagesci.HDF5DisplayUtils.displayFilter(filters(j));
                end
            end
            dispTxt = dispTxt + newline;
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayFilter(filter)
            % This helper function returns display text for the given filter (e.g., the
            % name of the filter)

            dispTxt = "";

            switch(filter.Name)
                case 'deflate'
                    deflateDesc = getString(message(...
                        'MATLAB:imagesci:h5disp:deflate',filter.Data));
                    dispTxt = dispTxt + sprintf(deflateDesc);
                case {'shuffle', 'fletcher32', 'nbit', 'szip'}
                    dispTxt = dispTxt + sprintf('%s', filter.Name);
                case 'scaleoffset'
                    scaleOffsetDesc = getString(message(...
                        'MATLAB:imagesci:h5disp:scaleOffset',filter.Data(1)));
                    dispTxt = dispTxt + sprintf(scaleOffsetDesc);
                otherwise
                    unrecognizedFilter = getString(message(...
                        'MATLAB:imagesci:h5disp:unrecognizedFilter',filter.Name));
                    dispTxt = dispTxt + sprintf(unrecognizedFilter);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayChunking(ChunkSize,level)
            % This function will display something like the example that follows below.
            %
            %         ChunkSize:  5000x1

            dispTxt = "";

            label = getString(message('MATLAB:imagesci:h5disp:chunkSize'));
            dispTxt = dispTxt + sprintf('%s%s:  ', ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), label);
            if isempty(ChunkSize)
                dispTxt = dispTxt + sprintf('[]');
            else
                dispTxt = dispTxt + sprintf('%d', ChunkSize(1));
                for j = 2:numel(ChunkSize)
                    dispTxt = dispTxt + sprintf('x%d',ChunkSize(j));
                end
            end
            dispTxt = dispTxt + newline;
        end

        %--------------------------------------------------------------------------
        function dispTxt = displayDataspace(dataspace,level)
            % This function will display something like the example that follows below.
            %
            %        Size:  4x1
            %        MaxSize:  InfxInf

            dispTxt = "";

            sizeLabel = getString(message('MATLAB:imagesci:h5disp:size'));
            maxsizeLabel = getString(message('MATLAB:imagesci:h5disp:maxSize'));
            validatestring(dataspace.Type,{'scalar','null','simple'});
            if strcmp(dataspace.Type,'simple')
                dispTxt = dispTxt + ...
                    sprintf('%s%s:  ', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), sizeLabel) + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displaySize(dataspace.Size) + ...
                    newline + sprintf('%s%s:  ', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), maxsizeLabel) + ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.displaySize(dataspace.MaxSize) + ...
                    newline;
            else
                dispTxt = dispTxt + sprintf('%s%s:  %s\n', ...
                    matlab.io.internal.imagesci.HDF5DisplayUtils.getIndent(level), ...
                    sizeLabel, dataspace.Type);
            end
        end

        %--------------------------------------------------------------------------
        function dispTxt = displaySize(Size)

            dispTxt = sprintf("%d", Size(1));
            for j = 2:numel(Size)
                dispTxt = dispTxt + sprintf('x%d', Size(j));
            end
        end

        %--------------------------------------------------------------------------
        function indent = getIndent(level)
            % Create an indentation amount specific to the depth level.
            indent = blanks(level*4);
        end

        %--------------------------------------------------------------------------
        function fid = openHelper(filename)
            % Performs a more resilient attempt to open a file. If the default fapl
            % does not work, try the others. This routine is almost identical to the
            % ones used by h5infoc and h5readc

            % First try the default
            try
                fid = H5F.open(filename);
                % If this works, then return
                return;
            catch ME
            end

            % Try the family file driver
            try
                fapl = H5P.create('H5P_FILE_ACCESS');
                H5P.set_fapl_family(fapl, 0, 'H5P_DEFAULT');
                fid = H5F.open(filename, 'H5F_ACC_RDONLY', fapl);

                % If it works, then the family driver is good enough
                H5P.close(fapl);
                return;
            catch
            end

            % Try the multi file driver
            try
                H5P.close(fapl);
                fapl = H5P.create('H5P_FILE_ACCESS');
                H5P.set_fapl_multi(fapl, true);
                fid = H5F.open(filename, 'H5F_ACC_RDONLY', fapl);

                H5P.close(fapl);
                return;
            catch
            end
            rethrow(ME);
        end

    end
end