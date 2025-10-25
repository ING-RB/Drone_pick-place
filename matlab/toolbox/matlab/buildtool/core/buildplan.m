function plan = buildplan(localFcns, options)
arguments
    localFcns (1,:) cell = {}
    options.RootFolder (1,1) string = defaultRootFolder()
    options.ImplicitTaskGroups (1,1) logical = false
end

import matlab.buildtool.internal.fixtures.CurrentFolderFixture;

plan = matlab.buildtool.Plan.withRootFolder(options.RootFolder, ImplicitTaskGroups=options.ImplicitTaskGroups);

plan = addFunctionTasks(plan, localFcns);

fixtures = [locateFixtures(plan.RootFolder), CurrentFolderFixture(plan.RootFolder)];
plan = addFixture(plan, fixtures);
end

function folder = defaultRootFolder()
stack = dbstack("-completenames");
if numel(stack) > 2 && ~isempty(stack(3).file)
    folder = fileparts(stack(3).file);
else
    folder = pwd();
end
end

function fixtures = locateFixtures(rootFolder)
import matlab.automation.internal.services.ServiceLocator;
import matlab.automation.internal.services.ServiceFactory;
import matlab.buildtool.internal.services.fixtures.FixtureLiaison;

namespace = "matlab.buildtool.internal.services.fixtures";
locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
serviceClass = ?matlab.buildtool.internal.services.fixtures.FixtureService;

locatedServiceClasses = locator.locate(serviceClass);
locatedServices = ServiceFactory.create(locatedServiceClasses);

liaison = FixtureLiaison(rootFolder);
fulfill(locatedServices, liaison);

fixtures = liaison.Fixtures;
end

% Copyright 2021-2024 The MathWorks, Inc.

% LocalWords:  completenames
