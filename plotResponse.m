%% Helper function: plotResponse
% Generates plots for a given transfer function + input signal 
% INPUTS: 
%   - fc: n-length vector of center frequencies to be used
%   - filters: n-length cell array of transfer functions specifying each band filter
%   - H_total: transfer function generated from given parameters (response) 
%   - H_total_unity: trasnfer function generated from gain = 1
%   - debug: Boolean; 1 to print debug info; 0 for nothing
% OUTPUTS:
%   - No returned values (only plots)

function [] = plotResponse(fc, filters, H_total, H_total_unity, debug)
    figure('Name', 'Individual bands + Unity Equalizer');
    hold on;
    
    % Run for each bandpass filter
    for i = 1:length(fc)
        bode(filters{i});
    end
    
    % Total system response with unity gain 
    bode(H_total_unity, '--');
    
    title('Frequency Response: Individual Bands and Unity');
    allBand = cell(1, length(fc));
    for i = 1:length(fc)
        allBand{i} = [num2str(fc(i)), ' Hz'];
    end
    legend(allBand);
    hold off;
    
    % FIGURE 2: total summed response w/ provided custom gains
    
    figure('Name','Summed Response')
    hold on;

    % SUMMED EQUALIZER 
    bode(H_total, 'r');
    bode(H_total_unity, 'b--');
    title('Overall Equalizer Response: Custom Gain + Unity')
    legend('Custom Gain', 'Unity')
    hold off;
    
    if debug == 1
        % Extract data points for analysis
        f = logspace(log10(20), log10(20000), 2000);
        w = 2*pi*f;
        [mag, ~] = bode(H_total, w);
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
        disp(['Min = ', num2str(magMin, '%.2f'), ...
            ' dB @ ', num2str(hzMin, '%.1f'), ' Hz | ', ...
            'Max = ', num2str(magMax, '%.2f'), ...
            ' dB @ ', num2str(hzMax, '%.1f'), ' Hz | ', ...
            'p-to-p = ', num2str(ptop, '%.2f'), ' dB'])
    end

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
end