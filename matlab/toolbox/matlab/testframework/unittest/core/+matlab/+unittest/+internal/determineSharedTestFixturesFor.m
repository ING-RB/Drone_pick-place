function fixtures = determineSharedTestFixturesFor(testClass)
% This function is undocumented and may change in a future release.

% Copyright 2016-2018 The MathWorks, Inc.

import matlab.unittest.internal.getAllTestCaseClassesInHierarchy;

classes = getAllTestCaseClassesInHierarchy(testClass);
sharedTestFixtures = flatten({classes.SharedTestFixtures});
sharedTestFixtures = getUniqueTestFixtures(sharedTestFixtures);

% Make a copy to keep from modifying the fixture handles stored on the metaclass.
fixtures = copy(sharedTestFixtures);
end

function X = flatten(X)
% Flatten the cell array into a 1xN vector of Fixture instances.
% Each element of the cell array X is what is specified in the class
% attribute, and could (in general) be an N-D cell array containing N_i-D
% fixture arrays.
import matlab.unittest.fixtures.EmptyFixture;
X = cellfun(@makerow, X, 'UniformOutput', false);
X = [EmptyFixture.empty(1,0), X{:}];
    
    function X = makerow(X)
        X = cellfun(@(x)x(:).', X, 'UniformOutput', false);
        X = [X{:}];
    end

end
