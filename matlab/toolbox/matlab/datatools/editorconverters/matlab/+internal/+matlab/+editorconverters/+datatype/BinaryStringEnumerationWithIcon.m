classdef BinaryStringEnumerationWithIcon 
	% This is an interface for data types that want to have their
	% editor be shown with a single toggle buttons with an icon

	% Copyright 2017-2023 The MathWorks, Inc.
	
	properties(Abstract, Constant)		
		% EnumeratedValues
		%
		% A 1xN cell array of chars, where the first value corresponds to
		% the toggle button being unchecked, and the second value
		% corresponds to the toggle button being checked
		%
		% Ex: {
		%      'off',
		%      'on'
		%      }
		EnumeratedValues
		
		% IconPath
		%
		% The ID of an icon in the icon catalog.		
		%		
		% Ex: "boldTextUI"
		%     
		IconName
	end		
end

