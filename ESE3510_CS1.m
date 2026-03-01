%% ESE 3510 Signals and Systems - Case Study #1
%%
% * Authors: Minh Duc Nguyen, Sonia Palamand 
% * Class: ESE 3510-01
% * Date: Started - 2/20/26 ; Completed - 3/XX/26
% * Contributions from: ______

%% 1: Center frequency and bandwidth for each frequency band
% [Bass, Low-Mid, Mid, High-Mid, Treble]

fc = [60, 230, 910, 3000, 14000];  % Center frequencies in Hz
% bw = [40, 150, 600, 2000, 8000];  % old Bandwidths in Hz 
bw = [100, 400, 1500, 5000, 20000]; % new bandwidths 

% Hz to rad/s conversion for CT transfer functions
% this is creating list of five values
w0 = 2 * pi * fc;   % resonant frequency (2pif)
beta = 2 * pi * bw; % bandwidth (R/L in series RLC circuit)

%% 2. Transfer functions for each filter 
% 2nd-order bandpass transfer function: H(s) = (beta * s) / (s^2 + beta * s + w0^2)

filters = cell(1, 5);

for i = 1:5
    num = [beta(i), 0];   %  tf() will see this as Beta(s) + 0
    den = [1, beta(i), w0(i)^2];
    filters{i} = tf(num, den); % builds continuous-time transfer function
end

%% 3. Gain array, Summation for total equilizer

gains_unity = [1,1,1,1,1]; % flat
gains_bass_boost = [4,2,1,1,1]; % lowest freq bands boosted
gains_treble_boost = [1,1,1,2,4];  % highest freq bands boosted

% "blank" transfer function. 0/1 = 0, but it's formatted as a transfer function object
H_total_unity = tf(0, 1);
H_total_bass = tf(0, 1);
H_total_treble = tf(0, 1);

% applies each gain, aggregates it to total system.
for i = 1:5
    H_total_unity = H_total_unity + (gains_unity(i) * filters{i});
    H_total_bass = H_total_bass + (gains_bass_boost(i) * filters{i});
    H_total_treble = H_total_treble + (gains_treble_boost(i) * filters{i});
end

%% 4. Plotting frequency responses 

% FIGURE 1: checking the individual bands and total system when gains are flat aka all 1
figure('Name', 'Individual bands and Unity Equalizer');
hold on;

% each bandpass filter
for i = 1:5
    bode(filters{i});
end

% total system response with unity gain 
bode(H_total_unity);

title('Frequency Response: Individual Bands and Unity');
legend('60 Hz', '230 Hz', '910 Hz', '3 kHz', '14 kHz', 'Total System (Unity)');
hold off;

% FIGURE 2: comparing 3 presets (unity, bass boost, treble boost)

figure('Name','Equalizers Comparison')
hold on;
% SUMMED EQUALIZER 
bode(H_total_unity);
bode(H_total_bass);
bode(H_total_treble);

title('Overall Equalizer Settings: Unity, Bass Boost, Treble Boost');
legend('Unity', 'Bass Boost', 'Treble Boost');
hold off;

%% 5. Approximate Impulse Response using lsim
% lsim(b,a,x,t) with x=[1 zeros(1,N)]

fs = 44100;   % audio sampling rate 
t = 0:(1/fs):0.1; % time vector going from 0 to 0.1 seconds
x_imp = [1, zeros(1, length(t)-1)]; % impulse input

figure('Name', 'Impulse Responses of All 5 Bands');

% Go through each filter, simulate the response
for i = 1:5
    % get numerator and denominator array of filter 
    [num_i, den_i] = tfdata(filters{i}, 'v'); % The 'v' param outputs array instead of cell
    
    % CT LCCDE response
    h_i = lsim(num_i, den_i, x_imp, t);
    
    % Stacked subplot
    subplot(5, 1, i);
    plot(t, h_i);
    
    title(['Impulse Response of Band ', num2str(i), ' (', num2str(fc(i)), ' Hz)']);
    xlabel('Time (seconds)');
    ylabel('Amplitude');
end


% what's next is to load the audio file 

% like [x, fs] = audioread()