classdef ProfileArgParser < handle
    % ProfileArgParser Argument parser class for the profile command.
    % TODO(g2710153): It might be possible to re-write this class, or even replace
    % it altogether with inputParser.
    % TODO(g2711971): There seems to be an issue with the mustBeTextScalar
    % validator being not filtered with CALLSTATS('pffilter') in this
    % file, so I have dropped their use to avoid tests failures.
    % This is a reminder to put them back when the issue is fixed.

    %   Copyright 2022 The MathWorks, Inc.

    properties (Access = private)
        % ValidOptions Set of valid options.
        %   The set of valid options can be configured using
        %   addOption/addOptionWithArg functions.
        ValidOptions

        % ValidActions Set of valid actions.
        %   The set of valid actions can be configured using
        %   addAction function.
        ValidActions
    end

    methods
        function obj = ProfileArgParser()
            obj.ValidOptions = containers.Map;
            obj.ValidActions = containers.Map;
        end

        function addOptionWithArg(obj, name, enumValue, argName, argAllowedValues, validationCallback)
            % Add an option which accepts an argument to the parser.
            arguments
                obj
                name % Should be {mustBeTextScalar} - see TODO(g2711971).
                enumValue (1,1) matlab.internal.profiler.cli.ProfileCLIOption
                argName % Should be {mustBeTextScalar} - see TODO(g2711971).
                argAllowedValues {mustBeA(argAllowedValues, ["cell", "function_handle"])}
                validationCallback {mustBeA(validationCallback, 'function_handle')} = @iNOP
            end

            if ~isa(argAllowedValues, 'function_handle')
                argAllowedValues = {argAllowedValues(:)};
            end

            obj.ValidOptions(name) = struct(...
                'EnumValue', enumValue, ...
                'ArgName', argName, ...
                'ArgAllowedValues', argAllowedValues, ...
                'ValidationCallback', validationCallback);
        end

        function addOption(obj, name, enumValue, validationCallback)
            % Add a flag-type option to the parser.
            arguments
                obj
                name % Should be {mustBeTextScalar} - see TODO(g2711971).
                enumValue (1,1) matlab.internal.profiler.cli.ProfileCLIOption
                validationCallback {mustBeA(validationCallback, 'function_handle')} = @iNOP
            end

            obj.ValidOptions(name) = struct(...
                'EnumValue', enumValue, ...
                'ValidationCallback', validationCallback);
        end

        function addAction(obj, name, enumValue)
            % Add an action to the parser.
            arguments
                obj
                name % Should be {mustBeTextScalar} - see TODO(g2711971).
                enumValue (1,1) matlab.internal.profiler.cli.ProfileCLIAction
            end

            obj.ValidActions(name) = enumValue;
        end

        function [action, options] = parse(obj, varargin)
            action = matlab.internal.profiler.cli.ProfileCLIAction.None;
            options = matlab.internal.profiler.Configuration;

            % Walk the input argument list consuming arguments passed one at a time.
            currentArgList = varargin;
            while (~isempty(currentArgList))
                [arg, currentArgList] = obj.getNextArg(currentArgList);
                if (~ischar(arg) || isempty(arg))
                    error(message('MATLAB:profiler:InvalidInputArgument'));
                end
                [option, value, currentArgList] = obj.getOption(arg, currentArgList);

                if option ~= matlab.internal.profiler.cli.ProfileCLIOption.None
                    % The argument is an option, so it is saved along with it's value
                    % (if it accepts one).
                    options.addOption(option.getOptionValue(value));
                else
                    % It's an action, but only one action is allowed.
                    if action ~= matlab.internal.profiler.cli.ProfileCLIAction.None
                        error(message('MATLAB:profiler:OnlyOneActionIsSupported',arg));
                    end
                    action = obj.getAction(arg);
                end
            end
        end
    end

    methods (Access = private)
        function actionName = getAction(obj, actionName)
            % Options should be set even if the action is not recognised.
            % So at this point we just save the actionName and error later
            % in PROFILE.
            % This is legacy behavior of PROFILE, kept for backwards compatibility.
            if obj.ValidActions.isKey(actionName)
                actionName = obj.ValidActions(actionName);
            end
        end

        function [nextArg, currentArgList] = getNextArg(~, currentArgList)
            nextArg = '';
            if ~isempty(currentArgList)
                % Parsing actions and options in lower-case to allow case-insensitivity (PRISM guideline).
                nextArg = lower(currentArgList{1});
                if numel(currentArgList) > 1
                    currentArgList = currentArgList(2:end);
                else
                    currentArgList = {};
                end
            end
        end

        function [option, optionValue, currentArgList] = getOption(obj, arg, currentArgList)
            option = matlab.internal.profiler.cli.ProfileCLIOption.None;
            optionValue = '';

            % Valid arguments start with '-'.
            if ~startsWith(arg, '-')
                return;
            end

            optionName = arg(2:end);

            if obj.ValidOptions.isKey(optionName)
                optionInfo = obj.ValidOptions(optionName);
                option = optionInfo.EnumValue;
            else
                error(message('MATLAB:profiler:UnknownInputOption', upper(optionName)));
            end

            if isProfileOn()
                error(message('MATLAB:profiler:ProfilerAlreadyStarted', upper(optionName)));
            end

            if isfield(optionInfo, 'ArgName')
                % If it is an option accepting an argument.
                if isempty(currentArgList)
                    error(message('MATLAB:profiler:InvalidInputArgumentOrder', optionInfo.ArgName, upper(optionName)));
                end
                [optionValue, currentArgList] = obj.getOptionValue(optionName, optionInfo.ArgName, ...
                    optionInfo.ArgAllowedValues, currentArgList);
            end
            % Extra validation can be done if a validation callback was
            % registered.
            obj.customValidation(optionName, optionValue, optionInfo.ValidationCallback);
        end

        function [optionValue, currentArgList] = getOptionValue(obj, optionName, argName, argAllowedValues, currentArgList)
            [optionValueArg, currentArgList] = obj.getNextArg(currentArgList);
            if  isa(argAllowedValues, 'function_handle')
                optionValue = argAllowedValues(optionName, optionValueArg);
            else
                % Allow partial matching of option arguments. This is
                % PRISM-compliant.
                foundIdx = strmatch(optionValueArg, argAllowedValues); %#ok<MATCH2>
                if (isempty(foundIdx))
                    error(message('MATLAB:profiler:UnsupportedInputArgument', argName));
                elseif (length(foundIdx) > 1)
                    error(message('MATLAB:profiler:AmbiguousInputOption', argName));
                else
                    optionValue = argAllowedValues{foundIdx};
                end
            end
        end

        function customValidation(~, optionInfo, optionValue, validationCallback)
            if ~isempty(validationCallback)
                validationCallback(optionInfo, optionValue)
            end
        end
    end
end

%% Internal Functions %%

function on = isProfileOn()
    on = matlab.internal.profiler.ProfilerService.getInstance.isRunning();
end

function iNOP(varargin)
end