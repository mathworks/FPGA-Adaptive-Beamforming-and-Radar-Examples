function dataCube = createRadarDataCubeMod(TxWaveform,RxArray,Fs,Fc, ...
    TargetPos,TargetVel,TargetRCS,...
    RngMax,RngActiveTime,RngGateTime,...
    CPILength,NumCPI,CPIDelta)

rng('default')

tx = phased.Transmitter('PeakPower',3000,'Gain',50);

freespaceTx = phased.FreeSpace('SampleRate',Fs,...
    'MaximumDistanceSource','Property',...
    'MaximumDistance',RngMax,...
    'OperatingFrequency',Fc);

radarTarget = phased.RadarTarget('MeanRCS',TargetRCS,'OperatingFrequency',Fc);

targetPlatform = phased.Platform('InitialPosition',TargetPos,'Velocity',TargetVel);

freespaceRx = phased.FreeSpace('SampleRate',Fs,...
    'MaximumDistanceSource','Property',...
    'MaximumDistance',RngMax,...
    'OperatingFrequency',Fc);

rxCollector = phased.Collector('Sensor',RxArray,'OperatingFrequency',Fc);

rx = phased.ReceiverPreamp('Gain',80,'NoiseFigure',30,'SampleRate',Fs);

TxPos = [0;0;0];
TxVel = [0;0;0];
RxPos = [0;0;0];
RxVel = [0;0;0];

RngActiveSamples = RngActiveTime*Fs;
RngGateSamples = RngGateTime*Fs;
PulsePeriod = length(TxWaveform)/Fs;

dataCube = complex(zeros(RngActiveSamples,CPILength,NumCPI));

T = 0;
for nn=1:NumCPI
    if nn > 1
        targetPlatform(T);
    end
    for ii=1:CPILength
        [TgtPos,TgtVel] = targetPlatform(PulsePeriod);
        temp = tx(TxWaveform);
        temp = horzcat(temp,temp);
        temp = freespaceTx(temp,TxPos,TgtPos,TxVel,TgtVel);
        temp = radarTarget(temp);
        temp = freespaceRx(temp,TgtPos,RxPos,TgtVel,RxVel);
        [~,ang] = rangeangle(TgtPos);
        temp = rxCollector(temp,ang);
        temp = rx(temp);
        dataCube(:,ii,nn) = temp(uint32(RngGateSamples+1):end,:);
    end
    T = T+CPIDelta;
end

end

