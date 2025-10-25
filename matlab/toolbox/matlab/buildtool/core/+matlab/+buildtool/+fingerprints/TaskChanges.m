classdef (Hidden) TaskChanges
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2024 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        ActionsChange matlab.buildtool.fingerprints.FingerprintChange {mustBeScalarOrEmpty}
        ClassInputChanges (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.FingerprintChange.empty())
        DynamicInputChanges (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.FingerprintChange.empty())
        ClassOutputChanges (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.FingerprintChange.empty())
        DynamicOutputChanges (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.FingerprintChange.empty())
        ArgumentsChange matlab.buildtool.fingerprints.FingerprintChange {mustBeScalarOrEmpty}
    end

    methods (Static)
        function changes = withAllPropertiesAdded(task, taskArguments, options)
            arguments
                task (1,1) matlab.buildtool.Task
                taskArguments (1,:) cell
                options.Fingerprinters (1,:) matlab.buildtool.fingerprints.Fingerprinter
                options.FingerprintContext (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end

            import matlab.buildtool.internal.fingerprints.TaskTrace;
            import matlab.buildtool.internal.fingerprints.computeTaskTrace;
            import matlab.buildtool.internal.fingerprints.detectTaskChanges;

            args = namedargs2cell(options);
            
            prevTrace = TaskTrace();
            currTrace = computeTaskTrace(task, taskArguments, args{:});

            changes = detectTaskChanges(prevTrace, currTrace);
        end
    end

    methods
        function changes = TaskChanges(options)
            arguments
                options.?matlab.buildtool.fingerprints.TaskChanges
            end

            for prop = string(fieldnames(options))'
                value = options.(prop);
                if isa(value, "dictionary")
                    changes.(prop) = changes.(prop).insert(value.keys(), value.values());
                else
                    changes.(prop) = options.(prop);
                end
            end
        end

        function tf = hasChanges(changes)
            tf = false;

            allChanges = [ ...
                changes.ActionsChange, ...
                changes.ClassInputChanges.values()', ...
                changes.DynamicInputChanges.values()', ...
                changes.ClassOutputChanges.values()', ...
                changes.DynamicOutputChanges.values()', ...
                changes.ArgumentsChange];

            for c = allChanges
                if c.isChanged()
                    tf = true;
                    return;
                end
            end
        end

        function c = classInputChange(changes, inputName)
            arguments
                changes (1,1) matlab.buildtool.fingerprints.TaskChanges
                inputName string {mustBeNonmissing}
            end

            tf = changes.ClassInputChanges.isKey(inputName);
            if ~all(tf)
                error(message("MATLAB:buildtool:TaskChanges:InputNotFound", inputName(find(~tf,1))));
            end

            c = changes.ClassInputChanges(inputName);
        end

        function c = classOutputChange(changes, outputName)
            arguments
                changes (1,1) matlab.buildtool.fingerprints.TaskChanges
                outputName string
            end

            tf = changes.ClassOutputChanges.isKey(outputName);
            if ~all(tf)
                error(message("MATLAB:buildtool:TaskChanges:OutputNotFound", outputName(find(~tf,1))));
            end

            c = changes.ClassOutputChanges(outputName);
        end

        function c = argumentsChange(changes)
            c = changes.ArgumentsChange;
        end

        function diags = diagnostics(changes)
            import matlab.buildtool.diagnostics.TaskChangeDiagnostic;

            if ~isempty(changes.ActionsChange)
                actionsDiag = TaskChangeDiagnostic("Actions", changes.ActionsChange);
            else
                actionsDiag = TaskChangeDiagnostic.empty();
            end

            if ~isempty(changes.ArgumentsChange)
                argumentsDiag = TaskChangeDiagnostic("Arguments", changes.ArgumentsChange);
            else
                argumentsDiag = TaskChangeDiagnostic.empty();
            end

            diags = [ ...
                actionsDiag, ...
                diagnosticsFromChangesDictionary("Input", changes.ClassInputChanges), ...
                diagnosticsFromChangesDictionary("Input", changes.DynamicInputChanges), ...
                diagnosticsFromChangesDictionary("Output", changes.ClassOutputChanges), ...
                diagnosticsFromChangesDictionary("Output", changes.DynamicOutputChanges), ...
                argumentsDiag];
        end
    end
end

function diags = diagnosticsFromChangesDictionary(type, changesDictionary)
import matlab.buildtool.diagnostics.TaskChangeDiagnostic;

diags = TaskChangeDiagnostic.empty(1,0);
for entry = changesDictionary.entries("struct")'
    if entry.Key == ""
        loc = sprintf("%ss", type);
    else
        loc = sprintf("%s '%s'", type, entry.Key);
    end
    diags(end+1) = TaskChangeDiagnostic(loc, entry.Value); %#ok<AGROW>
end
end