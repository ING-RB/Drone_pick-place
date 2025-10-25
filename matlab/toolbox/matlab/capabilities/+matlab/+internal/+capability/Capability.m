classdef Capability < uint64
  % Capability List of optional execution capabilities which may be enabled or disabled at runtime.
  enumeration

    % IMPORTANT NOTE ABOUT ADDING/MODIFYING/DELETING CAPABILITIES
    %   When adding, modifying, or deleting a capability enum, you must add, update or remove
    %   the corresponding error message id in the services.xml message catalog

    % Will interactive queries requiring user input have responses?
    % For examples, can the "blocking" prompts be unblocked:
    % - more
    % - pause
    % - input
    InteractiveCommandLine(matlab.internal.capability.getValue('InteractiveCommandLine')),

    % Is swing available?
    % Example functions:
    % - binningExplorer
    % - cftool
    % - classificationLearner
    Swing(matlab.internal.capability.getValue('Swing')),

    % Are we complex swing features available?
    % - Grid-based layout for document containers
    % - Custom Swing components
    % - Toolstrip v1
    % - JxBrowser UI
    % Example functions:
    % - cameraCalibrator
    % - colorThresholder
    % - fixedPointConverter
    ComplexSwing(matlab.internal.capability.getValue('ComplexSwing')),

    % Are we running on a local client (i.e. not remote client)?
    % Example functions:
    % - web
    % - sound
    LocalClient(matlab.internal.capability.getValue('LocalClient')),

    % Does the current platform support WebWindow (i.e. CEF)?
    WebWindow(matlab.internal.capability.getValue('WebWindow')),

    % Can execution-blocking UI-based dialogs receive user responses?
    % Note: Windows or controls that support interaction but don't block execution aren't examples of ModalDialogs
    % ModalDialog examples:
    % - inputdlg
    % - uigetfile
    ModalDialogs(matlab.internal.capability.getValue('ModalDialogs')),

    % Is debugging supported?
    % Example functions:
    % - dbstop
    % - dbstep
    Debugging(matlab.internal.capability.getValue('Debugging'))

  end

  methods (Static)
    function list = All
      % returns the list of all Capability values.
      list = enumeration('matlab.internal.capability.Capability');
    end

    function list = Current
      % returns the list of currently enabled Capability values.
      numericList = matlab.internal.capability.current;
      numericList = uint64(numericList);
      list = matlab.internal.capability.Capability(numericList);
    end

    function list = Unsupported(capabilityArray)
      % returns the disabled subset of capabilityArray
      current = matlab.internal.capability.Capability.Current;
      list = setdiff(capabilityArray, current);
    end

    function result = isSupported(capability)
        % returns 1 if capability is currently enabled, 0 if disabled
        current = matlab.internal.capability.Capability.Current;
        result = ismember(capability,current);
    end

    function require(capabilityArray)
      % throws an error if any of the capabilityArray Capability list is currently disabled.
      missingRequirements = matlab.internal.capability.Capability.Unsupported(capabilityArray);
      if (not(isempty(missingRequirements)))
          errorId = 'MATLAB:services:MissingRequiredCapability';
          reasonId = [errorId '_' char(missingRequirements(end))];
          me = matlab.internal.capability.UnsatisfiedCapability(errorId, message(reasonId).string);

          me.RequiredCapabilities = capabilityArray;
          me.EnabledCapabilities = matlab.internal.capability.Capability.Current;
          me.UnsatisfiedCapabilities = missingRequirements;
          throw(me);
      end
    end
  end
end

% Copyright 2018-2023 The MathWorks, Inc.
