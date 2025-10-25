function stepSize = adjustStep(stepSize, currentAxes, dirVector)

diag = sqrt(abs(diff(currentAxes.XLim))^2 +...
    abs(diff(currentAxes.YLim))^2 + abs(diff(currentAxes.ZLim)) ^ 2);

if diag < simpleNorm(dirVector)
    stepSize = stepSize/(simpleNorm(dirVector)/diag);
end

end


function norm = simpleNorm(vector)
norm = sqrt(vector(1)^2+vector(2)^2+vector(3)^2);
end