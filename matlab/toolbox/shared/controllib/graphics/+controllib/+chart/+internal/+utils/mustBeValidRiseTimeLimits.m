function mustBeValidRiseTimeLimits(value)
mustBeVector(value);
mustBeInRange(value,0,1);
mustBeGreaterThanOrEqual(value(2),value(1));
end