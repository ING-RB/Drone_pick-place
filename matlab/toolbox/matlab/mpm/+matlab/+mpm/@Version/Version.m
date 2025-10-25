classdef Version <  matlab.mixin.CustomCompactDisplayProvider
    properties (Access = public, Dependent)
        Major % uint32
        Minor % uint32
        Patch % uint32
        Prerelease % string
        Build % string
    end

    properties(SetAccess = private,GetAccess=public, Hidden = true)
        data (1,1) matlab.mpm.internal.VersionImpl = matlab.mpm.internal.VersionImpl("1.0.0")
    end

    methods
%% Constructor
        function obj = Version(versionStringOrMajor, minor, patch, opts)
            arguments
                versionStringOrMajor {mustBeTextIntegerOrMissing}= 1;
                minor {validateNumericInput} = 0;
                patch {validateNumericInput} = 0;
                opts.Prerelease {mustBeVector,mustBeText,mustBeNonmissing}
                opts.Build {mustBeVector,mustBeText,mustBeNonmissing}
            end
            if (isnumeric(versionStringOrMajor))
                if(isscalar(minor))
                    minor = repmat(minor,size(versionStringOrMajor));
                elseif (~isequal(size(versionStringOrMajor), size(minor)))
                    error(message('MATLAB:dimagree'));
                end

                if(isscalar(patch))
                    patch = repmat(patch,size(versionStringOrMajor));
                elseif (~isequal(size(versionStringOrMajor), size(patch)))
                    error(message('MATLAB:dimagree'));
                end
            end

            minor = uint32(minor);
            patch = uint32(patch);
            prerelease = string.empty;
            build = string.empty;

            if isfield(opts,"Prerelease")
                prerelease =opts.Prerelease;
            end
            if isfield(opts,"Build")
                build = opts.Build;
            end

            if (istext(versionStringOrMajor) && nargin ~=1)
                error(message("mpm:arguments:UnsupportedVersionArgument", "minor or patch"));
            end
            if (ischar(versionStringOrMajor))
                % better conversion function? 
                versionStringOrMajor= convertCharsToStrings(versionStringOrMajor);
            end
            try
                for i = 1:numel(versionStringOrMajor)
                    if ismissing(versionStringOrMajor(i)) % missing
                        obj(i).data.MissingValue = true;
    
                    elseif (isTextScalar(versionStringOrMajor(i))) % text
                        versionString = versionStringOrMajor(i);
                        if (isfield(opts,"Prerelease"))
                            if (contains(versionString, "-"))
                                error(message("mpm:arguments:UnsupportedVersionArgument", "prerelease"));
                            end
                            versionString = strcat(versionString,"-",strjoin(prerelease,"."));
                        end
        
                        if (isfield(opts,"Build"))
                            if (contains(versionString, "+"))
                                error(message("mpm:arguments:UnsupportedVersionArgument", "build"));
                            end
                            versionString = strcat(versionString,"+",strjoin(build,"."));
                        end
                        obj(i).data = matlab.mpm.internal.VersionImpl(fillTrailingZeros(versionString));
    
                    else % numeric
                        obj(i).data = matlab.mpm.internal.VersionImpl(versionStringOrMajor(i),minor(i), patch(i), prerelease, build);
                    end
                end
            catch ME 
                throw(ME)
            end 
            obj = reshape(obj,size(versionStringOrMajor));
        end

%% ismissing
        function out  = ismissing(obj)
            out = false(size(obj));
            for i = 1:numel(obj)
                out(i) =  obj(i).data.MissingValue;
            end
        end 

%% Setters/Getters
        % Major
        function out = get.Major(obj)
            out =  obj.data.Major;
        end
        function obj = set.Major(obj, value)
            arguments
                obj
                value {validateNumericInput}
            end
            obj.data.Major = uint32(value);
        end
    
        % Minor
        function out = get.Minor(obj)
            out =  obj.data.Minor;
        end
        function obj = set.Minor(obj, value)
            arguments
                obj
                value {validateNumericInput}
            end
            obj.data.Minor = uint32(value);
        end
    
        %Patch
        function out = get.Patch(obj)
            out =  obj.data.Patch;
        end
        function obj = set.Patch(obj, value)
            arguments
                obj
                value {validateNumericInput}
            end
            obj.data.Patch = uint32(value);
        end
    
        %Prerelease
        function out = get.Prerelease(obj)
            out =  obj.data.Prerelease;
        end
        function obj = set.Prerelease(obj, value)
            arguments
                obj
                value {mustBeVector,mustBeText,mustBeNonmissing}
            end
            obj.data.Prerelease = value;
        end
    
        % Build
        function out = get.Build(obj)
            out =  obj.data.Build;
        end
        function obj = set.Build(obj, value)
            arguments
                obj
                value {mustBeVector,mustBeText,mustBeNonmissing}
            end
            obj.data.Build = value;
        end

%% String
    function out = string(obj)
        out = reshape(string([obj.data]),size(obj));
    end
    
%% Comparators
    function tf = eq(obj,other)
        tf = binaryComparator(obj,other,@(lhs,rhs)eq(lhs,rhs));
    end
    function tf = lt(obj,other)
        tf = binaryComparator(obj,other,@(lhs,rhs)lt(lhs,rhs));
    end
    function tf = gt(obj,other)
        tf = binaryComparator(obj,other,@(lhs,rhs)gt(lhs,rhs));
    end    
    function tf = ne(obj,other)
        tf = binaryComparator(obj,other,@(lhs,rhs)ne(lhs,rhs),true);
    end
    function tf = le(obj,other)
        tf = binaryComparator(obj,other,@(lhs,rhs)le(lhs,rhs));
    end
    function tf = ge(obj,other)
        tf = binaryComparator(obj,other,@(lhs,rhs)ge(lhs,rhs));
    end

    function tf = isequal(varargin)
        narginchk(2,Inf);
        try
            tf = isequalUtil(false,varargin{:});
        catch ME
            if ME.identifier == "mpm:core:ComparisonNotDefined"
                tf = false;
                return
            else
                throw(ME);
            end
        end
    end

    function tf = isequaln(varargin)
        narginchk(2,Inf);

        % Ensure the logic to check equality is consistent between isequaln and
        % keyMatch.
        try
            tf = isequalUtil(true,varargin{:});
        catch ME
            if ME.identifier == "mpm:core:ComparisonNotDefined"
                tf = false;
                return
            else
                throw(ME);
            end
        end
    end

%% Display functions

        function displayRep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
            versionsAsStrings = arrayfun(@(x) string(x), obj);
            displayRep = widthConstrainedDataRepresentation(obj, displayConfiguration, width, ...
                                                            StringArray = versionsAsStrings, ...
                                                            Annotation = annotationForDisplay(obj, displayConfiguration), ...
                                                            AllowTruncatedDisplayForScalar = true);
        end

        function displayRep = compactRepresentationForColumn(obj,displayConfiguration, ~)
            versionsAsStrings = arrayfun(@(x) string(x), obj);
            displayRep = fullDataRepresentation(obj, displayConfiguration, ...
                                                StringArray = versionsAsStrings, ...
                                                Annotation = annotationForDisplay(obj, displayConfiguration));
        end

        function annotation = annotationForDisplay(obj, displayConfiguration)
            import matlab.display.DimensionsAndClassNameRepresentation;

            dimAndClsName = DimensionsAndClassNameRepresentation(obj, displayConfiguration);
            annotation = dimAndClsName.DimensionsString + " " + dimAndClsName.ClassName;
        end
    end
end


%% Helper validation functions
function mustBeTextIntegerOrMissing(val)
    if isnumeric(val)
        validateNumericInput(val)
        return;
    elseif istext(val)
       return;
    elseif all(ismissing(val),"all")
        return;
    end
    throwAsCaller(MException("mpm:arguments:InvalidArgumentType",...
                         message("mpm:arguments:InvalidArgumentType","versionStringOrMajor", "text or integer")));
end

function validateNumericInput(val)
    mustBeNumeric(val)
    mustBeReal(val)
    if  ~all(isinf(val) | isnan(val) | (val==floor(val)),"all")
        error(message("MATLAB:validators:mustBeInteger"));
    end
end

function out = isTextScalar(text)
    out = (isCharRowVector(text) || (isstring(text) && isscalar(text)));
end

function out = isCharRowVector(text)
    out = ischar(text) && (isrow(text) || isequal(size(text),[0 0]));
end

function out = istext(text)
    out = isCharRowVector(text) || isstring(text) || ...
         iscell(text) && matlab.internal.datatypes.isCharStrings(text);
end


function out = fillTrailingZeros(str)
    arguments
        str (1,1)
    end
    if (contains(str,"-") || contains(str,"+"))
        % don't attempt to backfill if version string might contain prerelease or build
        out = str;
    else
        out = ["1" "0" "0"];
        target = strsplit(str,".");
        if ~(length(target)<=3 && length(target)>=1 && isStringIntegerArray(target))
            % don't attempt to backfil if the string cannot be split into 1/2/3
            % string integers
            out = str; return;
        end

        out(1:length(target)) = target;
        out = strjoin(out,".");
    end
end 

function tf = isStringIntegerArray(arr)
    tf=true;
    for strElem = arr
        if strElem == "" ||...
          (strElem ~= string(num2str(uint32(str2double(strElem)))))
            tf=false; return;
        end
    end 
end

function out = binaryComparator(obj, other, op, missingFill)
    arguments
        obj
        other
        op (1,1) function_handle
        missingFill (1,1) logical = false;
    end

    try
        objIsVersion = isa(obj,"matlab.mpm.Version");
        otherIsVersion = isa(other,"matlab.mpm.Version");

        if (objIsVersion && otherIsVersion)
            obj_ind = reshape(1:numel(obj),size(obj));
            other_ind = reshape(1:numel(other),size(other));
            
            opImpl= @(lhs_idx,rhs_idx)...
                op(reshape([obj(lhs_idx).data],size(lhs_idx)),reshape([other(rhs_idx).data],size(rhs_idx)));

            out = bsxfun(opImpl,obj_ind,other_ind);
        elseif (isa(obj, "missing") || isa(other,"missing"))
            obj_ind = reshape(1:numel(obj),size(obj));
            other_ind = reshape(1:numel(other),size(other));

            opImpl = @(lhs,rhs)repmat(missingFill,getSizeOfLarger(lhs,rhs));
            
            out = bsxfun(opImpl,obj_ind,other_ind);
        elseif (objIsVersion) % either obj or other is a version
                out = op([obj.data],other);
        else
                out = op([other.data],obj);
        end
    catch ME
        throwAsCaller(ME);
    end

end

function out = getSizeOfLarger(lhs,rhs)
    if numel(lhs) >= numel(rhs)
        out = size(lhs);
    else
        out = size(rhs);
    end
end



function out = isequalUtil(treatMissingsAsEqual,varargin)
% this function does not need error handling, exceptions are handled by callers
    out = true;
    for i = 1:numel(varargin)
        if (treatMissingsAsEqual)
            if all(ismissing(varargin{1})) && all(ismissing(varargin{i}))
                continue;
            end 
        end

        if (~isequal(size(varargin{1}),size(varargin{i})))
            out= false; return;
        end

        res = eq(varargin{1},varargin{i});
        if ~all(res)
            out= false; return;
        end
        for k = 1:numel(varargin{1})
            if ~isequal(varargin{1}(k).Build,varargin{i}(k).Build)
                out= false; return;
            end
        end
    end
end
%   Copyright 2024 The MathWorks, Inc.
