clear all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Parameters to be set manually
%

music_path = "..\.\res\src\test.wav"; % the path and name of the bgm file
mp4_path = "..\.\res\input\src\"; % End with '\' for Windows and '/' for UNIX. The path of the videos.
mp4_num = 53; % The number of the videos, the name of the video must be 'i.mp4' where i = [1:mp4_num], for example, '10.mp4'.
try_time_input = 300000; % try times. The larger, the better effect, but takes more time.
time_tolerance = 9.95; % The maximum of the error of the output video's time.

% optimization parameter
% need to set manually:
% run 'debug.m'
% figure 8 and figure 88 shows the power of the videos' music (called p),
% figure 8 and 88 shows the same information but 8 is sorted and 88 is not.
% and figure 9 and figure 99 shows the power of bgm (called q),
% 9 is sorted and 99 is not.
% Then what you need TO DO is to estimate the parameter:
% Divide p into three parts: strong power, middle power and weak power.
% So you need to set p_lb to seperate middle power and weak power,
% and p_hb to seperate middle power and strong power.
% It is the same as q_lb and q_hb.
% Obviously, p_lb < p_hb and q_lb < q_hb
% !!! Another rule should be observed: !!!
% The number of the data points in each part of q must be larger than the
% corresponding part of p. For an example: the number of points that
% satisfies q > q_hb must be no more than p > p_hb, that is:
% length(q(q > q_hb)) <= length(p(p > p_hb)) must be true.
% Similarly,
% length(q(q < q_lb)) <= length(p(p < p_lb))
% length(q(q < q_hb & q > q_lb)) <= length(p(p < p_hb & p > p_lb))

p_lb = 0.002;
p_hb = 0.005;
q_lb = 0.008;
q_hb = 0.015;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Procedure
%

if p_lb >= p_hb
    error('Error: p_lb should be less than p_hb!');
end

if q_lb >= q_hb
    error('Error: q_lb should be less than q_hb!');
end

for i = 1:1:2
    % process bgm
    if i == 1
        [z, x, Fs, y1, y2, y3, y4, maxIdx, maxVal] = audio_process(music_path, true);
    else
        [z, x, Fs, y1, y2, y3, y4, maxIdx, maxVal] = audio_process(music_path);
    end

    % plot parameter
    plot_margin = 1.1; % y-grid margin
    x_grid_end = length(x) / Fs; % the max-val of x-grid. The max value of 'x_grid_end' is:length(y1) / Fs;

    figure(i * 2);

    subplot(6, 1, 1);
    plot([1:length(x)] / Fs, x);
    axis([0, x_grid_end, min(min(x) * plot_margin, 0), max(x) * plot_margin]);

    subplot(6, 1, 2);
    plot([1:length(y1)] / Fs, y1);
    axis([0, x_grid_end, 0, max(y1) * plot_margin]);

    subplot(6, 1, 3);
    plot([1:length(y2)] / Fs, y2);
    axis([0, x_grid_end, 0, max(y2) * plot_margin]);

    subplot(6, 1, 4);
    plot([1:length(y3)] / Fs, y3);
    axis([0, x_grid_end, min(min(y3) * plot_margin, 0), max(y3) * plot_margin]);

    subplot(6, 1, 5);
    plot([1:length(y4)] / Fs, y4);
    axis([0, x_grid_end, 0, max(y4) * plot_margin]);

    subplot(6, 1, 6);
    plot([1:length(y4)] / Fs, y4);
    hold on
    plot(maxIdx / Fs, maxVal, 'o');
    axis([0, x_grid_end, 0, max(y4) * plot_margin]);

    figure(i * 2 + 1);
    plot([1:length(z)] / Fs, z);
    axis([0, x_grid_end, min(z), max(z) * plot_margin]);
end

% process mp4
z_mp4{mp4_num} = [0; 0];
Fs_mp4(mp4_num) = 0;
x_mp4{mp4_num} = 0;

for i = 1:mp4_num
    [z_mp4{i}, x_mp4{i}, Fs_mp4(i), ~, ~, ~, ~, ~, ~] = audio_process(mp4_path + string(i) + ".mp4");
end

time_mp4(mp4_num) = 0.0; % Time of the mp4 videos in seconds .

for i = 1:length(z_mp4)
    time_mp4(i) = length(x_mp4{i}) / Fs_mp4(i);
end

average_time = mean(time_mp4);
average_time_in_bgm = round(average_time * Fs);

q_bgm(ceil(length(z) / average_time_in_bgm)) = 0;
q_idx = 1;
q_last_end = 0;

while q_last_end < length(x)
    q_bgm(q_idx) = norm(z(q_last_end + 1:min(q_last_end + average_time_in_bgm, length(x))));
    q_last_end = q_last_end + average_time_in_bgm;
    q_idx = q_idx + 1;
end

q_bgm = q_bgm(1:q_idx - 1);

p_mp4(mp4_num) = 0;

for i = 1:mp4_num
    p_mp4(i) = norm(z_mp4{i});
end

[p, p_mp4_idx] = sort(p_mp4, 'descend');
[q, q_bgm_idx] = sort(q_bgm, 'descend');

q_low_idx = q <= q_lb;
q_mid_idx = q > q_lb & q <= q_hb;
q_up_idx = q > q_hb;
p_low_idx = p <= p_lb;
p_mid_idx = p > p_lb & p <= p_hb;
p_up_idx = p > p_hb;

q_low = length(q(q_low_idx));
q_mid = length(q(q_mid_idx));
q_up = length(q(q_up_idx));

p_low = length(p(p_low_idx));
p_mid = length(p(p_mid_idx));
p_up = length(p(p_up_idx));

if (q_low > p_low)
    error('Error: q_lb and p_lb illegal! The number of points in weak parts of q should be no more than that of p! Please read the guide at the top of this file!');
end

if (q_mid > p_mid)
    error('Error: q_lb q_hb, p_lb and p_hb illegal! The number of points in middle parts of q should be no more than that of p! Please read the guide at the top of this file!');
end

if (q_up > p_up)
    error('Error: q_hb and p_hb illegal! The number of points in strong parts of q should be no more than that of p! Please read the guide at the top of this file!');
end

% random choose for several times
try_time = try_time_input;
itr = 0;
max_colleration = 0;
max_order(length(q_bgm_idx)) = 0;
order(length(q_bgm_idx)) = 0;

while itr < try_time

    if itr < try_time / 3
        p_low_choose = randperm(p_low, q_low) + p_up + p_mid;
        p_mid_choose = randperm(p_mid, q_mid) + p_up;
        p_up_choose = randperm(p_up, q_up);
        p_choose = sort([p_up_choose, p_mid_choose, p_low_choose]);
    else
        p_choose = sort(randperm(length(p_mp4), length(q_bgm)));
    end

    order(q_bgm_idx) = p_mp4_idx(p_choose);

    if sum(time_mp4(order)) < length(x) / Fs - time_tolerance || sum(time_mp4(order)) > length(x) / Fs + time_tolerance
        continue;
    end

    % Calculate colleration
    this_q_calculate_end = 0;
    this_colleration = 0;
    this_p = p_mp4(order);
    this_p = this_p / norm(this_p);

    for i = 1:length(order)

        if this_q_calculate_end >= length(q_bgm)
            break;
        end

        this_q_len = round(time_mp4(order(i)) * Fs);
        this_colleration = this_colleration + this_p(i) * norm(q(this_q_calculate_end + 1:min(this_q_calculate_end + this_q_len, length(q))));
        this_q_calculate_end = this_q_calculate_end + this_q_len;
    end

    % disp(this_colleration);
    if this_colleration > max_colleration
        max_colleration = this_colleration;
        max_order = order;
        % disp(order);
        % disp(itr);
    end

    itr = itr + 1;
end

if max_colleration == 0
    error('Error: No solution!');
end

p_result = p_mp4(max_order);

figure(888);
plot(z);
figure(999);
plot(p_result);

fid = fopen('..\Project-for-Signals-and-Systems-2021\input\input.txt', 'w');

if (fid <= 0)
    disp('File open failed!');
else
    fprintf(fid, '%d\n', max_order);
end

fclose(fid);
