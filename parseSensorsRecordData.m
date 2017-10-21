% this takes an ASCII encoded data file from the Android app Sensors Record
% and converts it into a structure that can be utilized in MATLAB
% Link to app in play store:
%    https://play.google.com/store/apps/details?id=pl.mrwojtek.sensrec.app
%
function [accelerometer sensorNames sensorData] = parseSensorsRecordData(datafile)
    f = fopen(datafile, 'r');
    if f == -1
        disp(['Could not open file ', datafile]);
        return;
    end
    l = fgetl(f);
    nameIndexMap = containers.Map;
    currentElementMap = containers.Map;

    sensorData = {};
    sensorNames = {};
    while true
        l = fgetl(f);
        if ~ischar(l)
            break;
        end
        fields = strsplit(l)';
        if strfind(fields{1}, '_acc')
            continue;
        end
        % sanity check on dimensionality
        if length(fields) == str2num(fields{4}) + 4
            if ~any(strcmp(sensorNames, fields{1}))
                sensorNames{end+1} = fields{1};
                sensorData{end+1} = zeros(1000, str2num(fields{4}) + 1);
                nameIndexMap(fields{1}) = length(sensorNames);
                currentElementMap(fields{1}) = 1;   % this is the next element to fill in
            end
   
            if size(sensorData{nameIndexMap(fields{1})},1) < currentElementMap(fields{1});
                % grow the array
                sensorData{nameIndexMap(fields{1})} = [sensorData{nameIndexMap(fields{1})}; zeros(size(sensorData{nameIndexMap(fields{1})}))];
            end
            sensorData{nameIndexMap(fields{1})}(currentElementMap(fields{1}),:) = [str2num(fields{3})/10^9; cellfun(@str2num, fields(5:end))];
            currentElementMap(fields{1}) = currentElementMap(fields{1}) + 1;
        end
    end
    k = nameIndexMap.keys;
    for i = 1 : length(nameIndexMap.keys)
        sensorData{nameIndexMap(k{i})} = sensorData{nameIndexMap(k{i})}(1:currentElementMap(k{i}) - 1, :);
    end
    accelerometer = sensorData{nameIndexMap('accel_0')};
end