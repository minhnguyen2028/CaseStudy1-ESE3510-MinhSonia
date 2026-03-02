


function y = processAudio(x, fs, H_total, windowLength, overlap, nfft)
    % Extract transfer function
    [num, den] = tfdata(H_total, 'v'); % Get numerator/denominator
    tAudio = (0:length(x)-1)' / fs; % Time vector
    % Process w/ lsim
    y = lsim(num, den, x, tAudio); 
    
    % Get FT transform (for the first second)
    x_SNIP = x(1:fs);
    y_SNIP = y(1:fs);
    N = length(x_SNIP); 
    fFT = (0:floor(N/2))' * fs/N; % Extract only half (other half redundant)
    xfs = fft(x_SNIP); yfs = fft(y_SNIP);
    
    % Plot waveforms
    figure('Name', 'Original vs Processed Waveforms + FFT')
    subplot(2, 1, 1);
    plot(tAudio, y)
    hold on; 
    plot(tAudio, x) 
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
    subplot(2, 1, 1); spectrogram(x, windowLength, overlap, nfft, fs, 'yaxis');
    title('Original Audio Signal');
    subplot(2, 1, 2); spectrogram(y, windowLength, overlap, nfft, fs, 'yaxis');
    title('Processed Audio Signal');
    sgtitle('Spectrogram of Original vs Processed Audio')
end