
clear; clc; close all;
rng(1);

N = 2000;   % Required dataset size



% TRANSMITTER PARAMETERS (Nx1 COLUMN VECTORS)

TxPower_dBm = randsample([2 5 10 14 17 20], N, true);
TxPower_dBm = TxPower_dBm(:);

SF = randsample([7 8 9 10 11 12], N, true);
SF = SF(:);

BW_kHz = randsample([125 250 500], N, true);
BW_kHz = BW_kHz(:);


%% --------------------------------------------------------------
% RECEIVER PARAMETERS (Nx1)
% --------------------------------------------------------------
dist_km = 0.1 + (10-0.1)*rand(N,1);   % receiver distance (0.1–10 km)

env_types = {'urban','suburban','rural'};
env_idx = randi(3, N, 1);
env = cell(N,1);
for i=1:N
    env{i} = env_types{env_idx(i)};
end


%% --------------------------------------------------------------
% LOSSES + SIGNAL METRICS (Nx1)
% --------------------------------------------------------------
PathLoss_dB     = zeros(N,1);
Shadowing_dB    = zeros(N,1);
Fading_dB       = zeros(N,1);
OtherLosses_dB  = zeros(N,1);

RSSI_dBm = zeros(N,1);
Noise_dBm = zeros(N,1);
SNR_dB = zeros(N,1);
PDR = zeros(N,1);
Coverage = strings(N,1);

fc = 865e6;
lambda = 3e8/fc;
k = 1.38e-23;
T0 = 290;
NF_dB = 6;

for i = 1:N

    d_m = dist_km(i) * 1000;
    BW_hz = BW_kHz(i) * 1e3;

    %% Free-space path loss
    FSPL = 20*log10(4*pi*d_m/lambda);

    %% Environment losses
    switch env{i}
        case 'urban'
            envLoss = 10 + 6*rand();
            shadow_sigma = 8;
        case 'suburban'
            envLoss = 5 + 4*rand();
            shadow_sigma = 6;
        case 'rural'
            envLoss = 2 + 3*rand();
            shadow_sigma = 4;
    end

    shadow = shadow_sigma * randn();
    %% ----------------------------------------------------------
    % RAYLEIGH FADING (Correct Mathematical Model)
    % -----------------------------------------------------------
    X = randn();
    Y = randn();
    rayleigh_amp = sqrt(X^2 + Y^2);
    fading = 20*log10(rayleigh_amp);    % Rayleigh fading in dB
    % -----------------------------------------------------------

    
    totalLoss = FSPL + shadow + fading + envLoss;

    %% RSSI calculation
    RSSI = TxPower_dBm(i) - totalLoss;

    %% Noise
    Noise = -174 + 10*log10(BW_hz) + NF_dB + randn()*1.5;

    %% SNR
    SNR = RSSI - Noise;

    %% PDR (sigmoid)
    PDR_val = 1 ./ (1 + exp(-0.6*(SNR - 3)));

    %% Assign values
    PathLoss_dB(i) = FSPL;
    Shadowing_dB(i) = shadow;
    Fading_dB(i) = fading;
    OtherLosses_dB(i) = envLoss;

    RSSI_dBm(i) = RSSI;
    Noise_dBm(i) = Noise;
    SNR_dB(i) = SNR;
    PDR(i) = PDR_val;

    %% Coverage Label
    if SNR >= 10
        Coverage(i) = "Good";
    elseif SNR >= 0
        Coverage(i) = "Moderate";
    else
        Coverage(i) = "Poor";
    end
end


%% --------------------------------------------------------------
% CREATE FINAL DATASET TABLE (Nx1 guaranteed)
% --------------------------------------------------------------
T = table(dist_km, SF, BW_kHz, TxPower_dBm, env, ...
          PathLoss_dB, Shadowing_dB, Fading_dB, OtherLosses_dB, ...
          RSSI_dBm, Noise_dBm, SNR_dB, PDR, Coverage);

%% --------------------------------------------------------------
% SAVE CSV
% --------------------------------------------------------------
writetable(T, 'LoRa_Receiver_Data.csv');
disp(" Dataset generated successfully!");
disp(" File saved as LoRa_Receiver_Data.csv");
disp(" Rows in dataset: " + height(T));
