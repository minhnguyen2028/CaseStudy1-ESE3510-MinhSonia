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
% --> Creates list of 5 values
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
gains_unity = [1,  1,1,1,1,1,  1]; % flat
gains_bass_boost = [1,  4,2,1,1,1,  1]; % lowest freq bands boosted
gains_treble_boost = [1,  1,1,1,2,4,  1];  % highest freq bands boosted

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

% total system response with unity gain 
bode(H_total_unity, '--');

title('Frequency Response: Individual Bands and Unity');
legend([num2str(fc(1)), ' Hz (passive)'], [num2str(fc(2)), ' Hz'], [num2str(fc(3)), ' Hz'], ...
       [num2str(fc(4)), ' Hz'], [num2str(fc(5)), ' Hz'], [num2str(fc(6)), ' Hz'], ...
       [num2str(fc(7)), ' Hz (passive)'], 'Total System (Unity)')
hold off;

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
    magdB = round(20*log10(squeeze(mag)), 2); wdB = round(w/(2*pi), 1);
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


% what's next is to load the audio file 

% like [x, fs] = audioread()