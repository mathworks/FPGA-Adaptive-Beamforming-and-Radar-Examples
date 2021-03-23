function plot_beam_patterns(hAxes,mvdrResponse,phaseShiftResponse,signalAngle,interfererAngle)

hold(hAxes,'off');
plot(hAxes,-90:90,mvdrResponse,'Color','#0072BD','LineStyle','-','LineWidth',2);
hold(hAxes,'on');
plot(hAxes,-90:90,phaseShiftResponse,'Color','#0072BD','LineStyle','--');
xline(hAxes,signalAngle,'g');
xline(hAxes,interfererAngle,'r');
xlim(hAxes,[-90 90]);
ylim(hAxes,[-50 10]);
title(hAxes,'Beamforming Pattern');
xlabel(hAxes,'Azimuth Angle (degrees)');
ylabel(hAxes,'Normalized Power (dB)');
legend(hAxes,{'MVDR','PhaseShift'},'Location','SouthWest');

end

