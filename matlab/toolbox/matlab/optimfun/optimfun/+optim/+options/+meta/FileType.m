classdef FileType < optim.options.meta.OptionType
%

%FileType metadata for an option that accepts a file
%
% FT = optim.options.meta.FileType(fileExt,label,category) constructs a
% FileType with the given file extension,label and category. All valid
% values must be character arrays with file names (with or without path)
% that have the given file extension.
%
% FileType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019-2023 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant)
        TypeKey = 'file';
        TabType = 'file';
    end
    
    % Inherited properties
    properties(SetAccess = protected, GetAccess = public)
        Category     
        DisplayLabel
        Widget
        WidgetData
    end
    
    % Class properties
    properties(SetAccess = private, GetAccess = public)
        % FileExt - the type of file (extension) that is valid for the
        % given option
        FileExt
    end
    
    methods
        % Constructor
        function this = FileType(fileExt,label,category)
            this.FileExt = fileExt;
            this.DisplayLabel = label;
            this.Category = category;
            this.Widget = 'matlab.ui.control.EditField';
            this.WidgetData = {};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class. 
        function [fileName,valid,errid,errmsg] = validate(this,optionName,value)
            valid = true;
            errmsg = '';
            errid = '';
            fileName = value;
            if ~isempty(value)
                
                % Immediately error if fileName is not a string scalar or
                % character vector. This prevents the subsequent call to which
                % throwing an internal error.
                if ~matlab.internal.datatypes.isScalarText(fileName)
                    valid = false;
                    msgid = 'MATLAB:optimfun:options:checkfield:fileNameNotScalarText';                    
                    errid = 'optim:options:meta:FileType:validate:FileNameNotScalarText';
                    errmsg = getString(message(msgid, optionName));
                    return
                end
                
                % Convert strings to char and strip beginning or ending
                % whitespace.
                value = optim.options.meta.prepStringForValidation(value);

                if isempty(value)
                    % Empty is a valid value
                    fileName = value;
                    return
                end
                % If file path is on matlab's path, use which to get the absolute path.
                fileName = which(value);
                if isempty(fileName)
                    % File path is expected to be absolute.
                    fileName = value;
                end
                
                % Basic check for appropriate file path and name.
                [pathstr,name,ext] = fileparts(fileName);
                if isempty(pathstr)
                    % Assume the file is in the current directory.
                    fileName = sprintf('.%s%s',filesep,fileName);
                    [pathstr,name,ext] = fileparts(fileName);
                end
                
                if isempty(pathstr) || isempty(name)
                    valid = false;
                    msgid = 'MATLAB:optimfun:options:checkfield:fileNameInvalid';
                    errid = 'optim:options:meta:FileType:validate:FileNameInvalid';
                    errmsg = getString(message(msgid, optionName));
                elseif isempty(ext) || ~strcmpi(ext,this.FileExt)
                    fileName = [fileName this.FileExt];
                end
            end
        end
    end
    
end

