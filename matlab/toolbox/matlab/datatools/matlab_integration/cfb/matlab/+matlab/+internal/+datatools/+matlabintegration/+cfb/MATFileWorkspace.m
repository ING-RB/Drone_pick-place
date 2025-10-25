classdef MATFileWorkspace < internal.matlab.variableeditor.MLWorkspace  & dynamicprops & matlab.mixin.indexing.RedefinesDot
    % MATFileWorkspace
    % Creates a custom workspace for a given MATFile

    % Copyright 2022-2025 The MathWorks, Inc.

    properties (Constant)
        MAX_BYTES_FOR_DISPLAY = 128;
        MAX_TOTAL_BYTES_FOR_DISPLAY = 1024;
        MAX_FILE_BYTES_FOR_DISPLAY = 1.2e7;
    end

    properties (SetAccess='private', GetAccess='public')
        MatFileName char = '';
        MatFile;
        MatFileSize;
        CurrentVariables = {};
        Variables
        WhosInfo;
    end

    properties(Access=protected)
        TotalBytesRead (1,1) double = 0;
        DoFullPreview (1,1) logical = true;
    end

    properties
        CaptureChanges (1,1) logical = true;
        CaptureTransitions (1,1) logical = false;
    end
    
    methods
        function this=MATFileWorkspace(filename)
            this.MatFileName = filename;
            s = dir(filename);
            this.MatFileSize = s.bytes;
            if (this.MatFileSize > matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace.MAX_FILE_BYTES_FOR_DISPLAY)
                this.DoFullPreview = false;
            end
            if ~endsWith(this.MatFileName, '.mat', 'IgnoreCase', true)
                this.MatFileName = [filename '.mat'];
            end
            
            if ~exist(this.MatFileName, 'file')
                s = struct(); %#ok<NASGU>
                save(this.MatFileName, '-struct', 's');
            end
            this.MatFile = matfile(this.MatFileName);

            this.updateProperties();
        end

        function variables = who(this) %#ok<*MANU>
            variables = cellstr(this.CurrentVariables);
        end
    
        function assignin(this, varName, value)
            this.setValue(varName, value);
        end
    end
    methods(Access='public')
        
        function value = getValue(this, prop)
            %Fetch the value of a variable within MATFile
            value = this.MatFile.(prop);
        end

        function isVar = isvariable(this, varName)
            isVar = ismember(varName, this.who);
        end

        function varargout = evalin(this, cmd) %#ok<*INUSL>
            if this.isvariable(cmd)
                var = this.Variables(cmd);
                if this.DoFullPreview &&...
                        this.TotalBytesRead < matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace.MAX_TOTAL_BYTES_FOR_DISPLAY && ...
                        var.WhosInfo.bytes <= matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace.MAX_BYTES_FOR_DISPLAY
                    varargout{1} = this.MatFile.(cmd);
                    this.TotalBytesRead = this.TotalBytesRead + var.WhosInfo.bytes;
                else
                    varargout{1} = this.Variables(cmd);
                end
            elseif strcmpi(cmd, 'who') || strcmpi(cmd, "builtin('who')")
                varargout{1} = this.who();
            elseif strcmpi(cmd, 'whos') || strcmpi(cmd, "builtin('whos')")
                if isempty(this.WhosInfo)
                    this.WhosInfo = whos(this.MatFile);
                end
                varargout{1} = this.WhosInfo;
            else
                if nargout > 0
                    varargout = this.evalin@internal.matlab.variableeditor.MLWorkspace(cmd);
                else
                    this.evalin@internal.matlab.variableeditor.MLWorkspace(cmd);
                end
            end
        end

        function s = getValuesStruct(obj, vars)
            arguments
                obj 
                vars = obj.who;
            end
            s = struct;
            for i=1:length(vars)
                varName = vars{i};
                s.(varName) = obj.getValue(varName);
            end
        end
    end

    %% Methods for RedefinesDot
    methods (Access=protected)
        function varargout = dotReference(obj, indexOp)
            varargout{1} = [];
            varName = indexOp(1).Name;
            if obj.isvariable(varName)
                val = obj.getValue(indexOp(1).Name);
                if length(indexOp) > 1
                    val = val.(indexOp(2:end));
                end
                [varargout{1:nargout}] = val;
            else
                if isprop(obj, varName)
                    try
                        [varargout{1:nargout}] = obj.(varName);
                    catch ME
                        internal.matlab.datatoolsservices.logDebug("wsb::matfileworkspace", "error accessing property in dotReference: " + ME.message);
                        varargout{1} = [];
                    end
                else
                    try
                        [varargout{1:nargout}] = obj.MatFile.(varName);
                    catch ME
                        internal.matlab.datatoolsservices.logDebug("wsb::matfileworkspace", "error accessing MATFile property in dotReference: " + ME.message);
                    end
                end
            end
        end

        function obj = dotAssign(obj, indexOp, varargin)
            varName = indexOp(1).Name;
            newValue = varargin{1};
            if obj.isvariable(varName)
                currentValue = obj.getValue(varName);
                if length(indexOp) > 1
                    % Do subsassign
                    currentValue.(indexOp(2:end)) = newValue;
                    % Set value for full copy back
                    newValue = currentValue;
                end
            end
            obj.assignin(varName, newValue);
        end
        
        function n = dotListLength(obj, indexOp, indexContext)
            s = obj.getValuesStruct;
            n = listLength(s, indexOp, indexContext);
        end
    end

    methods(Access='private')
        function updateProperties(this)
            if ~isempty(this.MatFile)
                this.Variables = containers.Map;

                if isempty(this.WhosInfo)
                    this.WhosInfo = whos(this.MatFile);
                end
                whosInfo = this.WhosInfo;

                % Create MATFileVariable cache
                for i=1:length(whosInfo)
                    wi = whosInfo(i);
                    varName = wi.name;
                    mfVar = matlab.internal.datatools.matlabintegration.cfb.MATFileVariable(varName, wi);
                    this.Variables(varName) = mfVar;
                end

                s = this.Variables.keys;

                if ~isempty(s)
                    fns = s;
                    removedVariables = {};
                    updatedVariables = {};
                    addedVariables = {};

                    if ~isempty(fns)
                        % Check for removed variables
                        if ~isempty(this.CurrentVariables)
                            for i=1:length(this.CurrentVariables)
                                varName = this.CurrentVariables{i};
                                if ~any(strcmp(fns, varName))
                                    removedVariables{end+1} = varName; %#ok<AGROW>
                                end
                            end
                        end

                        for i=1:length(fns)
                            varName = fns(i);
                            % Remove old properties
                            if ~isempty(this.CurrentVariables) && any(strcmp(this.CurrentVariables, varName))
                                updatedVariables{end+1} = varName; %#ok<AGROW>
                            else
                                addedVariables{end+1} = varName; %#ok<AGROW>
                            end
                        end
                    end
                    
                    if ~isempty(removedVariables)
                        this.dispatchEvent('VariablesRemoved', removedVariables, {});
                    end
                    
                    if ~isempty(addedVariables)
                        this.dispatchEvent('VariablesAdded', addedVariables, {});
                    end
                
                    if ~isempty(updatedVariables)
                        this.dispatchEvent('VariablesChanged', updatedVariables, {});
                    end
                    
                    this.CurrentVariables = fns;
                end
            end
        end

        function incrementFilename(this)
            currentFileName = this.MatFileName;
            
            pat = '(?<file>.*?)_(?<num>[0-9]+)\.';
            if regexp(currentFileName, pat)
                s = regexp(currentFileName, pat, 'names');
                n = str2double(s.num);
                newFileName = [s.file '_' int2str(n+1) '.mat'];
            else
                newFileName = [currentFileName(1:end-4) '_1.mat'];
            end
            
            this.MatFileName = newFileName;
        end
        
        function setValue(this, prop, value)
            if this.CaptureChanges
                if this.CaptureTransitions
                    this.incrementFilename();
                end
                this.MatFile.(prop) = value;
            end

            if ~any(strcmp(this.CurrentVariables, prop))
                this.dispatchEvent('VariablesAdded', prop, value);
            end

            this.dispatchEvent('VariablesChanged', prop, value);
        end

        
        function dispatchEvent(this, type, props, values)
            pce = internal.matlab.variableeditor.PropertyChangeEventData;
            pce.Properties = props;
            pce.Values = values;
            this.notify(type, pce);
        end
    end
end

