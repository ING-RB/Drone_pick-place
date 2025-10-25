classdef EmptyFixture < matlab.unittest.fixtures.Fixture
    % EmptyFixture - Concrete fixture implementation
    %
    %   EmptyFixture is a concrete fixture implementation which makes no
    %   environment changes. There is no need for users to interact with this
    %   Fixture directly.
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    methods(Hidden)
        function setup(~)
        end
    end
end
