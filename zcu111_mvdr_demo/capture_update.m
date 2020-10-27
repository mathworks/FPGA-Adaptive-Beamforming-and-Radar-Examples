function capture_update()

persistent data_p

% Get variables from base workspace
regWr = evalin('base','regWr');
REG_MAP = evalin('base','REG_MAP');
streamRd = evalin('base','streamRd');
hSpecAn = evalin('base','hSpecAn');

% Trigger a capture
regWr(true,REG_MAP.rx_capture_trig);
regWr(false,REG_MAP.rx_capture_trig);

% Read a frame
[data,valid] = streamRd();

if ~valid
    return
end

% reshape into individual channels
data = reshape(data,4,[]);

% grab real/imag from chan 1&2, discard chan 3&4
data = complex(data(1,:), data(2,:));

% make channels as columns
data = transpose(data);

% Cast to fi and reinterpret fraction length
data = cast_to_fi(data);
data = reinterpretcast(data, numerictype(1,32,30));

% Convert to double
data = double(data);

data_p = data;

% Update viewer
hSpecAn(data_p);

end

