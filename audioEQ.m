%% Helper function: audioEQ
% Generates custom filter response w/ specified parameters 
% INPUTS: 
%   - fc: n-length vector of center frequencies to be used
%   - Q: n-length vector of quality factors to be used (paired w/ fc)
%   - gains: n-length vector of gains to be used 
%   - debug: Boolean; 1 to print debug info; 0 for nothing
%   - makePlot: Boolean; 1 to generate plots; 0 for nothing
% OUTPUTS:
%   - filters: n-length cell array of transfer functions specifying each band filter
%   - H_total: transfer function generated from given parameters (response) 

function [filters, H_total] = audioEQ(fc, Q, gains, debug, makePlot)
    if ~nargin  % publishing misc
        return
    end

    % Bandwidth
    bw = fc./Q;
    
    if debug == 1
        disp('Frequencies | Bandwidths: ')
        for i = 1:length(fc)
            disp([num2str(fc(i)), ' Hz | ', num2str(round(bw(i))), ' Hz'])
        end
    end

    % Hz to rad/s conversion for CT transfer functions
    w0 = 2 * pi * fc;   % resonant frequency (2pif)
    beta = 2 * pi * bw; % bandwidth (R/L in series RLC circuit)
        
    % 2nd-order bandpass transfer function: H(s) = (beta * s) / (s^2 + beta * s + w0^2)
    filters = cell(1, length(fc));
    
    for i = 1:length(fc)
        num = [beta(i), 0];   %  tf() will see this as Beta(s) + 0
        den = [1, beta(i), w0(i)^2];
        filters{i} = tf(num, den); % builds continuous-time transfer function
    end
    
    % "blank" transfer function. 0/1 = 0, but it's formatted as a transfer function object
    H_total = tf(0, 1);
    H_total_unity = tf(0, 1);
    
    % applies each gain, aggregates it to total system.
    for i = 1:length(fc)
        H_total = H_total + (gains(i) * filters{i});
        H_total_unity = H_total_unity + (1 * filters{i});
    end
    
    % Measure peak magnitude of the unity system across audible range
    fNorm = logspace(log10(20), log10(20000), 5000);
    wNorm = 2 * pi * fNorm;
    [magUnity, ~] = bode(H_total_unity, wNorm);
    magUnity = squeeze(magUnity);
    unity_peak = max(magUnity);  % linear peak gain
    
    % Apply inverse scalar to all presets so unity peaks at 0 dB (gain = 1; normalized)
    H_total = H_total * (1 / unity_peak);
    H_total_unity = H_total_unity * (1 / unity_peak);
    
    % Will plot if set to 1
    if makePlot == 1
        plotResponse(fc, filters, H_total, H_total_unity, debug);
    end
end