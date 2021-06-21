%% Run this after reading matrix value out

% pNumCols = N1;
% pNumRows = N2;
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
iter = length(rdMat)/(pNumCols*pNumRows);



%% Compare against original radar data cube

outputReshape = reshape(rdMat,pNumCols,pNumRows);
expectedOutput = radarDataCube.';
plot(imag(outputReshape(:) - expectedOutput(:)))


