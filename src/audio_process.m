function [z, x, Fs, y1, y2, y3, y4, maxIdx, maxVal] = audio_process(path, ~)
    [x, Fs] = audioread(path);
    [len, div] = size(x);
    if div > 1
        x = sum(x')';
    end
    
    if nargin == 2
        len = Fs * 12;
        if (len <= length(x))
            x = x(1 : len);
        end
    end

    y1 = x .* x;

    basic = Fs / 40;
    % wndLen = max(round(len / (50 * (1 + 2e-4 * len))), 2);
    wndLen = max(round(basic), 2);
    hfWnd = hanning(wndLen);
    y2 = conv(y1, hfWnd);

    y3 = diff(y2);
    y4 = max(y3, 0);
    [y4Len, ~] = size(y4);

    interval = Fs / 2;
    tolerantInterval = interval / 3;
    nGroups = ceil(y4Len / interval) + 1;
    y4Tilde = y4;
    y4Tilde(nGroups * interval) = 0;
    [maxVal, maxIdx] = max(reshape(y4Tilde, interval, nGroups));
    maxIdx = maxIdx + [0 : nGroups - 1] * interval;
    inRange = (maxIdx <= y4Len);
    farAway = (([maxIdx(2 : end), 0] - maxIdx >= tolerantInterval)...
        | ([maxVal(2 : end), 0] < maxVal))...
        & ~(maxIdx - [0, maxIdx(1 : end - 1)] < tolerantInterval ...
            & maxVal < [0, maxVal(1 : end - 1)]);
    correct = logical(zeros(size(farAway)));
    correct(1) = true;
    correct(end) = true;
    legal = inRange & (farAway | correct);
    maxVal = maxVal(legal)';
    maxIdx = maxIdx(legal)';

    y4Tilde = y4;
    y4Tilde(maxIdx) = 0;
    y4Tilde = y4 - y4Tilde;

    %h = hanning(Fs * 2);
    %z = conv(y4Tilde, h);
    %z = z / max(z);     % transform |z| to 0~1
    
    %N = Fs * 1.3;
    N = Fs * 3;
    
    % z = conv(ones(N + 1, 1), y4Tilde);
    % offset = floor((N - 1) / 2);
    
    z = movmean(y4Tilde, N + 1);
end
