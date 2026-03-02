%% ESE 3510 Signals and Systems - Case Study #1
%%
% * Authors: Minh Duc Nguyen, Sonia Palamand 
% * Class: ESE 3510-01
% * Date: Started - 2/20/26 ; Completed - 3/XX/26
% * Contributions from: ______
close all

%% 1: Center frequency and bandwidth for each frequency band

% [Low Guard, Bass, Low-Mid, Mid, High-Mid, Treble, High Guard]
% * added 2 passive "guard bands" at ~10 Hz and ~92 kHz, outside the human auditory 
%   range, to smooth out steep slopes at extreme low/high frequency ranges 
fc = [10, 60, 240, 960, 3840, 15360, 92200];  % Center frequencies in Hz

% Bandwidth specifications using Q factors
Q = [0.3, 0.5, 0.6, 0.6, 0.6, 0.5, 0.3];  % Band-specific Q factors
bw = fc./Q;

% MISC
disp('Frequencies | Bandwidths: ')
for i = 1:length(fc)
    disp([num2str(fc(i)), ' Hz | ', num2str(round(bw(i))), ' Hz'])
end

% Hz to rad/s conversion for CT transfer functions
% --> Creates list of 7 values
w0 = 2 * pi * fc;   % resonant frequency (2pif)
beta = 2 * pi * bw; % bandwidth (R/L in series RLC circuit)

%% 2. Transfer functions for each filter 

% 2nd-order bandpass transfer function: H(s) = (beta * s) / (s^2 + beta * s + w0^2)
filters = cell(1, length(fc));

for i = 1:length(fc)
    num = [beta(i), 0];   %  tf() will see this as Beta(s) + 0
    den = [1, beta(i), w0(i)^2];
    filters{i} = tf(num, den); % builds continuous-time transfer function
end

%% 3. Gain array, Summation for total equilizer

% Note: guard bands are left as entirely passive (gain always 1)
% Another note: presets tuned for processing given audio files (SEE PART 6)
gains_unity = [1,  1,1,1,1,1,  1]; % flat
gains_bass_boost = [1,  4,2,0.8,1,1,  1]; % lowest freq bands boosted
gains_treble_boost = [1,  1,1,0.8,1.6,4,  1];  % highest freq bands boosted 

% "blank" transfer function. 0/1 = 0, but it's formatted as a transfer function object
H_total_unity = tf(0, 1);
H_total_bass = tf(0, 1);
H_total_treble = tf(0, 1);

% applies each gain, aggregates it to total system.
for i = 1:length(fc)
    H_total_unity = H_total_unity + (gains_unity(i) * filters{i});
    H_total_bass = H_total_bass + (gains_bass_boost(i) * filters{i});
    H_total_treble = H_total_treble + (gains_treble_boost(i) * filters{i});
end

% Measure peak magnitude of the unity system across audible range
fNorm = logspace(log10(20), log10(20000), 5000);
wNorm = 2 * pi * fNorm;
[magUnity, ~] = bode(H_total_unity, wNorm);
magUnity = squeeze(magUnity);
unity_peak = max(magUnity);  % linear peak gain

% Apply inverse scalar to all presets so unity peaks at 0 dB (gain = 1; normalized)
H_total_unity = H_total_unity * (1 / unity_peak);
H_total_bass = H_total_bass * (1 / unity_peak);
H_total_treble = H_total_treble * (1 / unity_peak);

allTotal = [H_total_unity, H_total_bass, H_total_treble]; % For analysis
allName = {'Unity', 'Bass', 'Treble'};

%% 4. Plotting frequency responses 

% FIGURE 1: checking the individual bands and total system when gains are flat (all = 1)
figure('Name', 'Individual bands and Unity Equalizer');
hold on;

% Run for each bandpass filter
for i = 1:length(fc)
    bode(filters{i});
end

% Total system response with unity gain 
bode(H_total_unity, '--');

title('Frequency Response: Individual Bands and Unity');
legend([num2str(fc(1)), ' Hz (passive)'], [num2str(fc(2)), ' Hz'], [num2str(fc(3)), ' Hz'], ...
       [num2str(fc(4)), ' Hz'], [num2str(fc(5)), ' Hz'], [num2str(fc(6)), ' Hz'], ...
       [num2str(fc(7)), ' Hz (passive)'], 'Total System (Unity)')
hold off;
% Adjust y-limits
axes_handles = findall(gcf, 'type', 'axes'); axes(axes_handles(3)); ylim([-120, 10]); 

% FIGURE 2: comparing 3 presets (unity, bass boost, treble boost)

figure('Name','Equalizers Comparison')
hold on;
% SUMMED EQUALIZER 
bode(H_total_unity, 'r');
bode(H_total_bass, 'b--');
bode(H_total_treble, 'g--');

% Extract data points for analysis
for i = 1:3
    H_tot = allTotal(i);
    f = logspace(log10(20), log10(20000), 2000);
    w = 2*pi*f;
    [mag, ~] = bode(H_tot, w);
    magdB = round(20*log10(squeeze(mag)), 2);
    % Audible human range: 20 Hz to 20 kHz
    idx = (f >= 20) & (f <= 20000);
    magAudible = magdB(idx);
    fAudible = f(idx);
    % Min
    [magMin, idxMin] = min(magAudible);
    hzMin = fAudible(idxMin);
    % Max
    [magMax, idxMax] = max(magAudible);
    hzMax = fAudible(idxMax);
    % Peak-to-peak
    ptop = peak2peak(magAudible);
    disp([allName{i}, ': Min = ', num2str(magMin, '%.2f'), ...
        ' dB @ ', num2str(hzMin, '%.1f'), ' Hz | ', ...
        'Max = ', num2str(magMax, '%.2f'), ...
        ' dB @ ', num2str(hzMax, '%.1f'), ' Hz | ', ...
        'p-to-p = ', num2str(ptop, '%.2f'), ' dB'])
end

title('Overall Equalizer Settings: Unity, Bass Boost, Treble Boost');
legend('Unity', 'Bass Boost', 'Treble Boost');
hold off;

%% 5. Approximate Impulse Response using lsim
% lsim(b,a,x,t) with x=[1 zeros(1,N)]

fs = 44100;   % audio sampling rate 
t = 0:(1/fs):0.05; % time vector going from 0 to 0.05 seconds
x_imp = [1, zeros(1, length(t)-1)]; % impulse input

figure('Name', 'Impulse Responses of All Bands');

% Go through each filter, simulate the response
for i = 1:length(fc)
    % get numerator and denominator array of filter 
    [num_i, den_i] = tfdata(filters{i}, 'v'); % The 'v' param outputs array instead of cell
    
    % CT LCCDE response
    h_i = lsim(num_i, den_i, x_imp, t);
    
    % Stacked subplot
    subplot(length(fc), 1, i);
    plot(t, h_i);
    title(['Impulse Response of Band ', num2str(i), ' (', num2str(fc(i)), ' Hz)']);
    xlabel('Time (seconds)');
    ylabel('Amplitude');
end

%% 6: Enhancing jazz audio clips w/ presets

% Load audio files
[x_giant_steps, fs_giant_steps] = audioread("Wavs\Giant Steps Bass Cut.wav");
[x_space_station, fs_space_station] = audioread("Wavs\Space Station - Treble Cut.wav");

% (A) Giant Steps (bass cut) --> bass boost preset
[num, den] = tfdata(H_total_bass, 'v'); % Get numerator/denominator
tAudioGS = (0:length(x_giant_steps)-1)' / fs_giant_steps; % Time vector
% Process w/ lsim
y_giant_stepsL = lsim(num, den, x_giant_steps(:, 1), tAudioGS); 
y_giant_stepsR = lsim(num, den, x_giant_steps(:, 2), tAudioGS); 
y_giant_steps = [y_giant_stepsL, y_giant_stepsR];

% Extract averaged (mono) audio signal for plotting
x_giant_steps_MONO = (x_giant_steps(:, 1) + x_giant_steps(:, 2))/2;
y_giant_steps_MONO = (y_giant_steps(:, 1) + y_giant_steps(:, 2))/2;

% Get FT transform (for the first second)
x_giant_steps_SNIP = x_giant_steps_MONO(1:fs_giant_steps);
y_giant_steps_SNIP = y_giant_steps_MONO(1:fs_giant_steps);
N = length(x_giant_steps_SNIP); 
fGS = (0:floor(N/2))' * fs_giant_steps/N; % Extract only half (other half redundant)
xFS_giant_steps = fft(x_giant_steps_SNIP); yFS_giant_steps = fft(y_giant_steps_SNIP);

% Plot waveforms
figure('Name', 'Original vs Bass-Boosted Waveforms + FFT of Giant Steps')
% Averaged (mono) processed
subplot(2, 1, 1);
plot(tAudioGS, y_giant_steps_MONO)
hold on; 
% Averaged (mono) original
plot(tAudioGS, x_giant_steps_MONO) 
xlabel('Time (s)'); ylabel('Amplitude'); axis tight;
title('Original vs Bass-Boosted Waveforms of Giant Steps'); hold off;
legend('Processed Waveform', 'Original Waveform');

% Plot FT (half)
subplot(2, 1, 2);
plot(fGS, abs(yFS_giant_steps(1:floor(N/2)+1))); hold on; 
plot(fGS, abs(xFS_giant_steps(1:floor(N/2)+1))); axis tight;
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('FT of Original vs Bass-Boosted Waveforms of Giant Steps')
legend('Processed Waveform', 'Original Waveform'); hold off;

% Plot spectrogram (averaged mono audio)
figure('Name', 'Spectrogram of Original vs Processed Giant Steps')
subplot(2, 1, 1); spectrogram(x_giant_steps_MONO, 256, 200, 256, fs_giant_steps);
title('Original Audio Signal'); clim([-150, -40])
subplot(2, 1, 2); spectrogram(y_giant_steps_MONO, 256, 200, 256, fs_giant_steps);
title('Processed Audio Signal'); clim([-150, -40])
sgtitle('Spectrogram of Original vs Processed Giant Steps Audio')


% (B) Space Station (treble cut) --> treble boost preset
[num, den] = tfdata(H_total_treble, 'v'); % Get numerator/denominator
tAudioSS = (0:length(x_space_station)-1)' / fs_space_station; % Time vector
% Process w/ lsim
y_space_stationL = lsim(num, den, x_space_station(:, 1), tAudioSS); 
y_space_stationR = lsim(num, den, x_space_station(:, 2), tAudioSS); 
y_space_station = [y_space_stationL, y_space_stationR];

% Extract averaged (mono) audio signal for plotting
x_space_station_MONO = (x_space_station(:, 1) + x_space_station(:, 2))/2;
y_space_station_MONO = (y_space_station(:, 1) + y_space_station(:, 2))/2;

% Get FT transform (for the first second)
x_space_station_SNIP = x_space_station_MONO(1:fs_space_station);
y_space_station_SNIP = y_space_station_MONO(1:fs_space_station);
N = length(x_space_station_SNIP); 
fSS = (0:floor(N/2))' * fs_space_station/N; % Extract only half (other half redundant)
xFS_space_station = fft(x_space_station_SNIP); yFS_space_station = fft(y_space_station_SNIP);

% Plot waveforms
figure('Name', 'Original vs Treble-Boosted Waveforms + FFT of Space Station')
% Averaged (mono) processed
subplot(2, 1, 1);
plot(tAudioSS, y_space_station_MONO)
hold on; 
% Averaged (mono) original
plot(tAudioSS, x_space_station_MONO) 
xlabel('Time (s)'); ylabel('Amplitude'); axis tight;
title('Original vs Treble-Boosted Waveforms of Space Station'); hold off;
legend('Processed Waveform', 'Original Waveform');

% Plot FT (half)
subplot(2, 1, 2);
plot(fSS, abs(yFS_space_station(1:floor(N/2)+1))); hold on; 
plot(fSS, abs(xFS_space_station(1:floor(N/2)+1))); axis tight;
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('FT of Original vs Treble-Boosted Waveforms of Space Station')
legend('Processed Waveform', 'Original Waveform'); hold off;

% Plot spectrogram (averaged mono audio)
figure('Name', 'Spectrogram of Original vs Processed Space Station')
subplot(2, 1, 1); spectrogram(x_space_station_MONO, 256, 200, 256, fs_space_station);
title('Original Audio Signal');
subplot(2, 1, 2); spectrogram(y_space_station_MONO, 256, 200, 256, fs_space_station);
title('Processed Audio Signal');
sgtitle('Spectrogram of Original vs Processed Space Station Audio')


% Listen to processed audios
sound(y_giant_steps, fs_giant_steps)
pause(15)
sound(y_space_station, fs_space_station)
pause(15)


%% 7: Enhancing bird vocalizations 

% Note: created helper functions to redo entire process above

% Load in bird audio
[xBird, fsBird] = audioread("Wavs\SNR Recording 2026-02-15 08_58.wav");

% Generate spectrogram to visualize frequencies
windowLength = round(0.01 * fsBird);   % 10 ms window
overlap = round(0.8 * windowLength);   % 80% overlap
nfft = 1024;
figure('Name', 'Spectrogram of Bird Vocalization Recording')
spectrogram(xBird, windowLength, overlap, nfft, fsBird, 'yaxis');

% Target 1: 3-3.5 kHz range 
% > appears to contain series of short high-low chirps
fc1 = [100, 500, 1000, 3250, 9000, 20000];  % center frequencies centered around 3.25 kHz
Q1 = [0.001, 0.001, 0.01, 10, 0.01, 0.001];
gains1 = [0.01, 0.01, 0.01, 10, 0.01, 0.01];

% Generate equalizer
[filters1, H_total1] = audioEQ(fc1, Q1, gains1, 1, 1);

% Process signal
y1 = processAudio(xBird, fsBird, H_total1, windowLength, overlap, nfft);
% sound(y1, fsBird)

% TODO: consider overtones; identify a few more birds