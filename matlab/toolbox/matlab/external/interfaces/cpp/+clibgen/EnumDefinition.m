classdef EnumDefinition < handle
    % EnumDefinition MATLAB definition of an enumeration
    % This class contains the MATLAB definition for a C++ enumeration present in the header
    % EnumDefinition properties:
    %   Description         - Description of the enumeration as provided by the publisher
    %   DetailedDescription - Detailed description of the enumeration as provided by the publisher
    
    % Copyright 2018-2024 The MathWorks, Inc.
    properties(Access=public)
        Description         string
        DetailedDescription string
    end
    properties(SetAccess=private)
        CPPName         string;
        MATLABType      string;
        Valid           logical = false;
        MATLABName      string;
        Entries         string;
    end
    properties(SetAccess=private, WeakHandle)
        DefiningLibrary clibgen.LibraryDefinition
    end    
    properties(Access=private)
        EnumInterface   internal.cxxfe.ast.types.EnumType;
    end
    properties(Access=?clibgen.internal.Accessor)
        EntryDescriptions struct
    end
    
    methods(Access=private)
        function validateEntries(~, entries, enumInterface)
            if(isempty(entries) && enumInterface.Strings.Size() == 0)
                return;
            end
            if not(numel(entries) == enumInterface.Strings.Size())
                error(message("MATLAB:CPP:InvalidEnumEntryCount",...
                    enumInterface.getFullyQualifiedName(),...
                    enumInterface.Strings.Size()));
            end
            s = enumInterface.Strings.toArray();
            result = ismember(entries, s);
            indices = find(~result);
            if not(isempty(indices))
                error(message("MATLAB:CPP:InvalidEnumEntry", ...
                    entries(indices(1)),...
                    enumInterface.getFullyQualifiedName()));
            end
        end
        
        function validateEnumerantDescriptions(~, enumerantDescriptions, entries)
            if not(numel(enumerantDescriptions) == numel(entries))
                error(message('MATLAB:CPP:ArraySizeMismatch'));
            end
            for i = 1:numel(enumerantDescriptions)
                validateattributes(enumerantDescriptions(i),{'char','string'},{'scalartext'});
            end
        end
        
        function verifyMatlabType(~, mlType, enumInterface)
            validateattributes(mlType, {'char','string'},{'scalartext', 'nonempty'});
            annotation = enumInterface.Annotations(1);
            if not(strcmp(mlType, annotation.mwUnderlyingType))
                error(message("MATLAB:CPP:InvalidEnumMlType", annotation.mwUnderlyingType));
            end
        end
        
        function verifyMatlabName(~, mlName, enumInterface)
            validateattributes(mlName, {'char','string'},{'scalartext', 'nonempty'})
            splitname = split(string(mlName),'.');
            valid = all(matlab.lang.makeValidName(splitname(1:end)) == splitname);
            if(~valid)
                error(message('MATLAB:CPP:InvalidName'));
            end
            annotation = enumInterface.Annotations(1);
            originalSplitName = split(annotation.name,'.');
            if(numel(splitname)==numel(originalSplitName))
                for i = 1:numel(splitname)-1
                    if not(splitname(i)==originalSplitName(i))
                        error(message("MATLAB:CPP:InvalidEnumMlName", mlName, originalSplitName{end}, ...
                            annotation.name));
                    end
                end
            else
                error(message("MATLAB:CPP:InvalidEnumMlName", mlName, originalSplitName{end}, ...
                    annotation.name));
            end
        end
    end
    
    methods(Access=?clibgen.LibraryDefinition)
        function obj = EnumDefinition(libraryDef, cppName, mlType, mlName, entries, enumInterface, description, detailedDescription, entryDescriptions)
            parser = inputParser;
            addRequired(parser, "LibraryDefinition", @(x) (isa(x, "clibgen.LibraryDefinition")));
            addRequired(parser, "EnumInterface",     @(x) isa(x, "internal.cxxfe.ast.types.EnumType"));
            addRequired(parser, "CPPName",           @(x) validateattributes(x, {'char','string'},{'scalartext', 'nonempty'}));
            addRequired(parser, "MATLABType",        @(x) verifyMatlabType(obj, x, enumInterface));
            addRequired(parser, "MATLABName",        @(x) verifyMatlabName(obj, x, enumInterface));
            addRequired(parser, "Enumerants",        @(x) validateEntries(obj, x, enumInterface));
            addRequired(parser, "Description",       @(x) validateattributes(x, {'char','string'},{'scalartext'}));
            addParameter(parser, "DetailedDescription", "", @(x) validateattributes(x, {'char','string'},{'scalartext'}));
            addParameter(parser, "EnumerantDescriptions", string.empty, @(x) validateEnumerantDescriptions(obj, x, entries));
            parser.KeepUnmatched = false;
            parse(parser, libraryDef, enumInterface, cppName, mlType, mlName, entries, description);
            obj.DefiningLibrary = libraryDef;
            obj.CPPName = cppName;
            obj.MATLABType = mlType;
            obj.MATLABName = mlName;
            obj.Entries = string(entries);
            obj.EnumInterface = enumInterface;
            obj.Description = description;
            obj.DetailedDescription = string(detailedDescription);
            for i = 1:numel(entryDescriptions)
                obj.EntryDescriptions(i).Entry = obj.Entries(i);
                obj.EntryDescriptions(i).Description = entryDescriptions(i);
            end
            obj.Valid = true;
            annotation = enumInterface.Annotations.toArray;
            annotation.name = obj.MATLABName;
            annotation.enumerantDescriptions.clear;
            for i = 1:numel(entryDescriptions)
                annotation.enumerantDescriptions.add(entryDescriptions(i));
            end
        end
        
        function addToLibrary(obj)
            enumAnnotations = obj.EnumInterface.Annotations.toArray;
            enumAnnotations(1).integrationStatus.inInterface = true;
            
            % update inInterface field for all owning scope except the
            % compilation unit which has mwMetadata annotations and not
            % ScopeAnnotation
            parent = obj.EnumInterface.OwningScope;
            while (~isempty(parent) && ~isa(parent,"internal.cxxfe.ast.source.CompilationUnit"))
                scopeAnnotations = parent.Annotations.toArray;
                scopeAnnotations(1).integrationStatus.inInterface = true;
                parent = parent.Parent();
            end
        end
        
        function summaryStr = summary(obj, ~)
            switch(nargin)
                case 1
                    % Show the MATLAB of the enumeration
                    summaryStr = sprintf("Enumeration " + obj.MATLABName + "\n");
                    for en = obj.Entries
                        enCell = en(1);
                        summaryStr = summaryStr + "  " + enCell(1) + "\n";
                    end
                case 2
                    % call is summary(obj, 'mapping')
                    summaryStr = sprintf("\nC++:    Enumeration " + obj.CPPName + "\n");
                    summaryStr = sprintf(summaryStr + "MATLAB: Enumeration " + obj.MATLABName + "\n");
                    for en = obj.Entries
                        enCell = en(1);
                        summaryStr = sprintf(summaryStr + "  " + enCell(1) + "\n");
                    end
            end
        end
    end
    
    methods
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            annotations = obj.EnumInterface.Annotations.toArray;%#ok<MCSUP>
            annotations(1).description = desc;
        end

        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            obj.DetailedDescription = details;
            annotations = obj.EnumInterface.Annotations.toArray;%#ok<MCSUP>
            annotations(1).detailedDescription = details;
        end
    end
end
