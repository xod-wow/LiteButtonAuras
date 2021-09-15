--[[----------------------------------------------------------------------------

    LiteButtonAuras
    Copyright 2021 Mike "Xodiv" Battersby

    I took the idea for the HLS gradients from AdiButtonAuras. I still don't
    know if this is worth all this processing, OR if this is fast enough to
    run every frame.

----------------------------------------------------------------------------]]--

local _, LBA = ...

LBA = LBA or {}

local min, max, abs = math.min, math.max, math.abs

local function hueToV(m1, m2, hue)
    hue = hue % 1
    if hue < 1/6 then
        return m1 + (m2-m1)*hue*6
    elseif hue < 1/2 then
        return m2
    elseif hue < 2/3 then
        return m1 + (m2-m1)*(2/3-hue)*6
    else
        return m1
    end
end

local function hlsToRgb(h, l, s)
    if s == 0 then
        return l, l, l
    end
    local m2
    if l < 0.5 then
        m2 = l * (1+s)
    else
        m2 = (l+s) - (l*s)
    end
    local m1 = 2*l - m2
    return hueToV(m1, m2, h+1/3), hueToV(m1, m2, h), hueToV(m1, m2, h-1/3)
end

local function rgbToHls(r, g, b)
    local minC, maxC = min(r, g, b), max(r, g, b)
    local l = (minC + maxC)/2
    if minC == maxC then
        return 0, l, 0
    end
    local h, s
    if l < 0.5 then
        s = (maxC-minC) / (maxC+minC)
    else
        s = (maxC-minC) / (2-maxC-minC)
    end
    local rc = (maxC-r) / (maxC-minC)
    local gc = (maxC-g) / (maxC-minC)
    local bc = (maxC-b) / (maxC-minC)
    if r == maxC then
        h = bc - gc
    elseif g == maxC then
        h = 2 + rc - bc
    else
        h = 4 + gc - rc
    end
    return (h/6) % 1, l, s
end

local function interpolateRgb(perc, r1, g1, b1, r2, g2, b2)
    local h1, l1, s1 = rgbToHls(r1, g1, b1)
    local h2, l2, s2 = rgbToHls(r2, g2, b2)

    -- L and S are linear interpolated
    local l = l1 + (l2-l1) * perc
    local s = s1 + (s2-s1) * perc

    -- Hue is a degree coordinate in radians on a circle that wraps. We want
    -- the smallest of the two angles between them.
    local dh = h2 - h1
    if dh < -0.5  then
        dh = dh + 1
    elseif dh > 0.5 then
        dh = dh - 1
    end

    h = (h1 + dh*perc) % 1
    return hlsToRgb(h%1, l, s)
end

function LBA.TimerRGB(duration)
    if duration <= 3 then
        return interpolateRgb(duration/3, 1, 0, 0, 1, 1, 0)
    elseif duration <= 10 then
        return interpolateRgb((duration-3)/7, 1, 1, 0, 1, 1, 1)
    else
        return 1, 1, 1
    end
end
