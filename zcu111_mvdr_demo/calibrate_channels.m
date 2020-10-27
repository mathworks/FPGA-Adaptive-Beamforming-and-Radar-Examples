function coeffs = calibrate_channels(data)
% This function computes complex coefficients to align amplitude and phase
% across all channels (narrowband only)

% ensure columns as channels
if (size(data,2) > size(data,1))
   data = data.'; 
end

% FFT each channel
f = fft(double(data),length(data),1);

% Get the peak for each channel
[~,idx] = max(abs(f),[],1);
peak = f(idx,:);
peak = peak(1,:);

% Normalize everything to channel 1
coeffs = transpose(peak(1)./peak);

end
