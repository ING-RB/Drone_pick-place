classdef FeatureCategory
    % FEATURECATEGORY - Enumeration class that defines feature categories.

    % Copyright 2024 The MathWorks, Inc.

    enumeration
        % APPLET - Applet launchable category.
        Applet

        % LIVETASK - LiveTask launchable category.
        LiveTask

        % HARDWARESETUP - Hardware Setup launchable category.
        HardwareSetup

        % EXAMPLE - Example launchable category.
        Example

        % SIMULINKMODEL - Simulink Model launchable category.
        SimulinkModel

        % HELPDOC - Help Documentation launchable category.
        HelpDoc
    end
end