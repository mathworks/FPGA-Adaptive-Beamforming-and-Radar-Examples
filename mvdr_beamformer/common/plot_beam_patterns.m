function plot_beam_patterns(hAxes,mvdrResponse,phaseShiftResponse,signalAngle,interfererAngle)
% Helper function for beam-pattern plotting
%
%   Copyright 2021 The MathWorks, Inc.

az = -90:90;
sigAzIdx = find(az==signalAngle,1);
intAzIdx = find(az==interfererAngle,1);
sigLevel = mvdrResponse(sigAzIdx);
intLevel = mvdrResponse(intAzIdx);

mvdrValid = ~isinf(sigLevel) && ~isinf(intLevel);

hold(hAxes,'off');
plot(hAxes,az,mvdrResponse,'Color','#0072BD','LineStyle','-','LineWidth',2);
hold(hAxes,'on');
plot(hAxes,az,phaseShiftResponse,'Color','#0072BD','LineStyle','--');

if mvdrValid
    yregion(hAxes,sigLevel,intLevel,'FaceColor','#faf5d4');
end

xline(hAxes,signalAngle,'g');
xline(hAxes,interfererAngle,'r');

if mvdrValid
    yline(hAxes,sigLevel,'--','Color',[0.5 0.5 0.5]);
    yline(hAxes,intLevel,'--','Color',[0.5 0.5 0.5]);
end

xlim(hAxes,[az(1) az(end)]);
ylim(hAxes,[-50 10]);
title(hAxes,'Beamforming Pattern');
xlabel(hAxes,'Azimuth Angle (degrees)');
ylabel(hAxes,'Normalized Power (dB)');
legend(hAxes,{'MVDR','PhaseShift'},'Location','SouthWest');

end

