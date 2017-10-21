global SAMPLE_PERIOD PEAK_THRESHOLD VOLUME_THRESHOLD SUBDIVISIONS ...
    BEAT1_THRESHOLD DECAY;
SAMPLE_PERIOD = 0.04; % Length of time that frequency is sampled over
PEAK_THRESHOLD = 0.04; % Cutoff amplitude for peak detection
VOLUME_THRESHOLD = 500; % Cutoff amplitude for note vs rest detection
BEAT1_THRESHOLD = 0.1; % Cutoff amplitude for finding first note played
SUBDIVISIONS = 4; % Number of subdivisions per beat
DECAY = 0.9; % Expected decrease in note amplitude between samples

clf;
transcribe({'TestData2.m4a','TestData1.m4a','FastPiano.m4a',...
            'LowPiano.m4a','Trombone.m4a','Trumpet.m4a',...
            'Piccolo.m4a','Flute.m4a'},...
            {'TestData2.txt'});

% Turn audio and accelerometer data into notes and rhythms
function transcribe(file, footfile)
    global SAMPLE_PERIOD;
    j = round((length(file)+1)/3);
    k = 1+(length(file)>1)+(length(file)>2);
    for i = 1:length(file)
        % Plot raw sound data
        subplot(j, k, i);
        hold on;
        [x, Fs] = audioread(cell2mat(file(i)));
        plot((1:length(x))/Fs, x);
        title(cell2mat(file(i)));
        
        % If no accel file, sample at regular intervals
        if i>length(footfile)
            regularIntervalPlot(x, Fs, SAMPLE_PERIOD);
            continue
        end
        
        % Find beats
        accel = parseSensorsRecordData(cell2mat(footfile(i)));
        accel = accel(120:end, :);
        t = accel(:,1)-accel(1,1);
        jz = conv(accel(:,4)-accel(1,4), [-1, 1], 'same');
        beats = t(getBeats(jz));
        beat1 = getBeat1(x)/Fs;
        beats = beats - beats(1) + beat1;
        plot(beats, zeros(1,length(beats)), 'o');
        
        % Find notes
        irregularIntervalPlot(x, Fs, SAMPLE_PERIOD, beats);
    end
end

% Plot the notes in an audio file sampled based on the given beats
function irregularIntervalPlot(x, Fs, period, beats)
    global SUBDIVISIONS;
    beats = interp1(beats, 1:1/SUBDIVISIONS:length(beats));
    notes = zeros(length(beats), 1);
    volumes = zeros(length(beats), 1);
    for i = 1:length(beats)
        if i<length(beats)
            t = beats(i)+(beats(i+1)-beats(i))/(SUBDIVISIONS*4);
        else
            t = beats(i)+(beats(i)-beats(i-1))/(SUBDIVISIONS*4);
        end
        notes(i) = getNote(getFrequency([t, t+period], x, Fs));
        volumes(i) = max(x(round(t*Fs)+1:round((t+period)*Fs)));
    end
    plot(beats, real(notes), 'k.');
    groupNotes(notes, volumes)
end

% Group notes that are the same pitch together
function output = groupNotes(notes, volumes)
    global DECAY;
    output = zeros(2,0);
    k = 1;
    for i = 1:length(notes)
        if i<k
            continue
        end
        duration = 1;
        for j = i+1:length(notes)
            if notes(i)==notes(j)
                if notes(i) == sqrt(-1) || (volumes(j)/volumes(i) < DECAY)
                    duration = duration + 1;
                end
            else
                break
            end
        end
        k = k + duration;
        output = cat(2, output, [notes(i); duration]);
    end
end

% Plot the notes in an audio file sampled at a regular interval
function regularIntervalPlot(x, Fs, period)
    notes = zeros(int16(length(x)/Fs/period)-2, 1);
    for i = 1:length(notes)
        t = i*period;
        notes(i) = getNote(getFrequency([t, t+period], x, Fs));
    end
    plot((1:length(notes))*period, real(notes), 'k.');
end

% Determine the frequency of audio data over a given time interval
function freq = getFrequency(interval, x, Fs)
    global PEAK_THRESHOLD VOLUME_THRESHOLD;
    t0 = round(interval(1)*Fs)+1;
    t1 = round(interval(2)*Fs)+1;
    period = interval(2)-interval(1);
    subx = x(t0:t1);
    fourier = (abs(fft(subx, round(length(subx)*2))));
    fourier_flipped = flip(fourier);
    [~, I] = firstPeak(fourier, PEAK_THRESHOLD);
    [~, I2] = firstPeak(fourier_flipped, PEAK_THRESHOLD);
    f = (I-1)*Fs/length(subx)/2;
    f2 = I2*Fs/length(subx)/2;
    freq = mean([f, f2]);
    if max(fourier)<VOLUME_THRESHOLD*period
        freq = 1i;
    end
end

% Find the first peak in a Fourier transform while ignoring overtones
function [peak, I] = firstPeak(data, threshold)
    [m, i] = max(data);
    data = data - mean(data(1:i));% - data(round(i*5/8));
    for j = 1:int16(0.6*i)
        if (data(j)>threshold*m) && (data(j+1)<data(j))
            for overtone = [6,4,3,2]
                if abs(i/j-overtone)<.1
                    peak = data(j);
                    I = i/overtone;
                    return
                end
            end
        end
    end
    peak = m;
    I = i;
end

% Determine the note given a frequency (i = rest)
function note = getNote(f)
    if f==1i
        note = f;
    else
        fA = f/440;
        note = round(12*log(fA)/log(2));
    end
end

% Determine the time indices of foot taps
function beats = getBeats(a)
    global BEAT1_THRESHOLD;
    beats = [];
    m = max(a);
    for i = 1:length(a)
        if isempty(beats) || (i-beats(end)) > 15
            if a(i) > m*BEAT1_THRESHOLD
                [~,j] = max(a(i:i+15));
                beats = cat(1,beats,j+i);
            end
        end
    end
end

% Determine the time index of the first note played
function beat1 = getBeat1(x)
    global BEAT1_THRESHOLD;
    beat1 = 0;
    m = max(x);
    for i = 1:length(x)
        if x(i) > m*BEAT1_THRESHOLD
            [~,j] = max(x(i:i+15));
            beat1 = j+i;
            return
        end
    end
end