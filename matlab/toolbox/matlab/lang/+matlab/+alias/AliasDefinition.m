classdef (Sealed) AliasDefinition < matlab.mixin.CustomDisplay
    %AliasDefinition Represent new and old names for a renamed class
    % An AliasDefinition object describes the new name and one or more old 
    % names (aliases) for a renamed class.  The new name is the actual name
    % of the class, and the list of old names represents all of the former
    % names for the class.  There can only ever be one new name for a
    % class, which must match the actual name of the class as it exists on 
    % disk. There can be more than one alias if the class has been renamed 
    % multiple times.
    %
    % For example, if a class "Old" is renamed to "New", create an alias
    % definition with NewName containing the string "New" and OldNames 
    % containing the string "Old".  The class definition must be updated to
    % use the name "New" and saved as New.m.  If the same class is 
    % subsequently renamed in a later release to "Newer", update the
    % existing alias definition with NewName = "Newer".  Specify the
    % OldNames property using the string array ["New", "Old"].  The class
    % definition must be updated to use the name "Newer" and saved as
    % Newer.m.  
    % 
    % When a class has more than one old name, it is important to keep the 
    % list of old names (aliases) in the proper order, with more recent 
    % aliases coming before older ones.  Maintaining the list in the proper 
    % chronological order provides the greatest amount of compatibility 
    % support.  Failure to maintain the proper order can result in
    % inconsistent behavior when using your renamed class in older versions 
    % of your software.  
    %
    % An AliasDefinition object can only be created using the addAlias 
    % method of the AliasFileManager class.
    %
    % See also matlab.alias.AliasFileManager, matlab.alias.AliasFileManager/addAlias, 
    % class, classdef

    %  Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Transient)
        NewName (1,1) string {mustBeNonmissing}
        OldNames (1,:) string {mustBeNonempty, mustBeNonmissing} = ""
    end

    properties(Transient, Hidden)
        WarnOnOldName (1,1) logical = false
    end

    methods (Access = {?matlab.alias.AliasFileManager})
        function obj = AliasDefinition(newName, oldNames, warnOnOldName)
            obj.NewName = newName;
            obj.OldNames = oldNames;
            obj.WarnOnOldName = warnOnOldName;
        end
    end

    methods
        %These values are class names, which could be package-qualified, 
        %so break each name into parts, then check each part
        function ad = set.NewName(ad, name)
            splitName = split(name,".");
            mustBeValidVariableName(splitName);
            ad.NewName = name;
        end

        function ad = set.OldNames(ad, names)
            for i=1:numel(names)
                splitName = split(names(i),".");
                mustBeValidVariableName(splitName);
            end
            ad.OldNames = names;
        end
    end
    
    methods(Hidden)
        function e = jsonencode(obj, args)
        %

        % A custom jsonencode method is required because the jsonencode   
        % function omits hidden properties.
            arguments
                obj matlab.alias.AliasDefinition
                args.PrettyPrint = false;
                args.ConvertInfAndNaN = true;
            end
            s = struct('NewName', {obj.NewName}, 'OldNames', {obj.OldNames}, ...
                'WarnOnOldName', {obj.WarnOnOldName});
            c = namedargs2cell(args);
            e = jsonencode(s, c{:});
        end
    end
    
    methods (Access = protected)
        function displayNonScalarObject(objArr)
            len = length(objArr);
            newNameList = strings(1, len);
            oldNamesList = strings(1, len);
            
            for i = 1:len
                obj = objArr(i);
                newNameList(i) = obj.NewName;
                oldNamesList(i) = join(obj.OldNames,{'" "',});
            end
            newNameStr = string(newNameList');
            oldNamesStr = string(oldNamesList');
            
            tempTable = table(newNameStr, oldNamesStr, 'VariableNames',{'New Name', 'Old Name(s)'});
          
            %Preserve current state of hyperlink support
            str = formattedDisplayText(tempTable, "SuppressMarkup", ~matlab.internal.display.isHot);
          
            fprintf("%s\n", getHeader(objArr));
            fprintf("%s\n", str);
        end
        
        function header = getHeader(obj)
            if isscalar(obj) || isempty(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                dimstr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
                header = [...
                    '  ', ...
                    getString(message('MATLAB:aliasFileManager:NonScalarDisplayHeader', dimstr, className)),...
                    newline];
            end
        end
    end
end

