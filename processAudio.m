%% Helper function: processAudio
% Processes bird vocalization audio signal w/ a provided transfer function/filter
% INPUTS: 
%   - x: n-length (mono) audio signal vector to be processed
%   - fs: sampling frequency of the audio signal
%   - H_total: transfer function generated from given parameters (response) 
%   - windowLength, overlap, nfft: parameters for the spectrogram
%   - doPlot: Boolean; creates additional plots if 1
%   - limits: length-4 vector of x/y limits for spectrogram [x1 x2 y1 y2]
%   - doCascade: integer; cascades for specified # of times if give
% OUTPUTS:
%   - No returned values (only plots)


function y = processAudio(x, fs, fRange, H_total, windowLength, overlap, nfft, doPlot, limits, doCascade)
    xOrig = x;  % Store original signal

    % Cascade (if positive)
    if nargin < 10 || isempty(doCascade)  % checks if doCascade is given or not
        doCascade = 0;
    end

    if doCascade > 0
        x = processAudio(x, fs, fRange, H_total, windowLength, overlap, nfft, 0, 0, doCascade-1);
    end

    % Extract transfer function
    [num, den] = tfdata(H_total, 'v'); % Get numerator/denominator
    tAudio = (0:length(x)-1)' / fs; % Time vector
    % Process w/ lsim
    y = lsim(num, den, x, tAudio); 
    
    % Get FT transform (for the first second)
    x_SNIP = xOrig(1:fs);
    y_SNIP = y(1:fs);
    N = length(x_SNIP); 
    fFT = (0:floor(N/2))' * fs/N; % Extract only half (other half redundant)
    xfs = fft(x_SNIP); yfs = fft(y_SNIP);
    
    if doPlot == 1
        % Plot waveforms
        figure('Name', 'Original vs Processed Waveforms + FFT')
        subplot(2, 1, 1);
        plot(tAudio, y)
        hold on; 
        plot(tAudio, xOrig) 
        xlabel('Time (s)'); ylabel('Amplitude'); axis tight;
        title('Original vs Processed Waveforms'); hold off;
        legend('Processed Waveform', 'Original Waveform');
        
        % Plot FT (half)
        subplot(2, 1, 2);
        plot(fFT, abs(yfs(1:floor(N/2)+1))); hold on; 
        plot(fFT, abs(xfs(1:floor(N/2)+1))); axis tight;
        xlabel('Frequency (Hz)'); ylabel('|X(f)|');
        title('FT of Original vs Processed Waveforms')
        legend('Processed Waveform', 'Original Waveform'); hold off;
        
        % Plot spectrogram
        figure('Name', 'Spectrogram of Original vs Processed Audio')
        subplot(2, 1, 1); spectrogram(xOrig, windowLength, overlap, nfft, fs, 'yaxis');
        title('Original Audio Signal'); xlim([limits(1), limits(2)]); ylim([limits(3), limits(4)]);
        subplot(2, 1, 2); spectrogram(y, windowLength, overlap, nfft, fs, 'yaxis');
        title('Processed Audio Signal'); xlim([limits(1), limits(2)]); ylim([limits(3), limits(4)]);
        sgtitle('Spectrogram of Original vs Processed Audio')

        % Compare specified band energies
        yEBefore = bandpower(xOrig, fs, fRange);
        yEAfter = bandpower(y, fs, fRange);
        
        % Compare signal-to-noise ratio improvement using low wind noise (~0-1 kHz) as reference noise
        xNoise = bandpower(xOrig, fs, [0, 1000]);
        yNoise = bandpower(y, fs, [0, 1000]);
        yRBefore = yEBefore/xNoise;
        yRAfter = yEAfter/yNoise;
        ySNR = 10*log10(yRAfter/yRBefore);
   
         disp(['TARGET [', num2str(fRange) ,'] Hz: Initial Energy: ', num2str(yEBefore), ...
              ' | Processed Energy: ', num2str(yEAfter), ...
              ' | SNR: ', num2str(ySNR), ' dB']);
    end
end